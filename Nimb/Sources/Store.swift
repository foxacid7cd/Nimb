// SPDX-License-Identifier: MIT

import Algorithms
import AsyncAlgorithms
import Collections
import ConcurrencyExtras
import CustomDump
import Foundation

@MainActor
public class Store: Sendable {
  @dynamicMemberLookup
  public struct APIProxy: Sendable {
    private var api: API<ProcessChannel>

    fileprivate init(api: API<ProcessChannel>) {
      self.api = api
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<API<ProcessChannel>, T>) -> T {
      api[keyPath: keyPath]
    }
  }

  public let updates: AsyncStream<(state: State, updates: State.Updates)>

  let instance: Instance

  //  private func startCursorBlinkingTask() {
  //    guard let cursorStyle = _state.currentCursorStyle else {
  //      return
  //    }
  //    if
  //      let blinkWait = cursorStyle.blinkWait,
  //      blinkWait > 0,
  //      let blinkOff = cursorStyle.blinkOff,
  //      blinkOff > 0,
  //      let blinkOn = cursorStyle.blinkOn,
  //      blinkOn > 0
  //    {
  //      cursorBlinkingTask = Task {
  //        do {
  //          try await Task.sleep(for: .milliseconds(blinkWait))
  //
  //          while true {
  //            dispatch(Actions.SetCursorBlinkingPhase(value: false))
  //            try await Task.sleep(for: .milliseconds(blinkOff))
  //
  //            dispatch(Actions.SetCursorBlinkingPhase(value: true))
  //            try await Task.sleep(for: .milliseconds(blinkOn))
  //          }
  //        } catch { }
  //      }
  //    }
  //  }

  private let apiTasksChannel = AsyncChannel< @Sendable (API<ProcessChannel>) async throws -> Any? > ()

  private let actionsChannel = AsyncChannel<Action>()
  private var cursorBlinkingTask: Task<Void, Never>?
  private var previousReportedOuterGridSize: IntegerSize?
  private var previousReportedOuterGridSizeInstant = ContinuousClock().now
  private var outerGridSizeThrottlingTask: Task<Void, Never>?
  private let outerGridSizeThrottlingInterval: Duration = .milliseconds(1000 / 120)
  private var previousMouseMove: (modifier: String, gridID: Grid.ID, point: IntegerPoint)?
  private var latestUIEventsBatch = [UIEvent]()
  private let alertsChannel = AsyncChannel<Alert>()

  public var alerts: AsyncStream<Alert> {
    alertsChannel.buffer(policy: .unbounded).eraseToStream()
  }

  public var api: API<ProcessChannel> {
    instance.api
  }

  public init(instance: Instance, debug: State.Debug, font: Font) {
    self.instance = instance

    let initialState = State(debug: debug, font: font)

    let applyUIEventsActions = instance.api.neovimNotifications
      .compactMap { [alertsChannel] neovimNotificationsBatch in
        var actions = [Action]()

        for notification in neovimNotificationsBatch {
          switch notification {
          case let .redraw(uiEvents):
            actions.append(Actions.ApplyUIEvents(uiEvents: uiEvents))
          case let .nvimErrorEvent(event):
            await alertsChannel.send("nvimErrorEvent received \(dump: event)")
          case let .nimbNotify(value):
            await alertsChannel.send("nimbNotify received \(dump: value)")
          }
        }

        return actions.isEmpty ? nil : actions
      }
      .flatMap(\.async)

    updates = merge(actionsChannel, applyUIEventsActions)
      .buffer(policy: .unbounded)
      .reductions(into: (state: initialState, updates: State.Updates())) {
        [alertsChannel] result,
          action in
        if result.updates.needFlush {
          result.updates = State.Updates(needFlush: false)
        }
        let updates = await action.apply(to: &result.state, handleError: { error in
          Task {
            await alertsChannel.send(.init(error))
          }
        })
        result.updates.formUnion(updates)
      }
      .filter(\.updates.needFlush)
      .throttle(for: .milliseconds(1000 / 60), clock: .continuous) { previousStateUpdates, stateUpdates in
        var updates = previousStateUpdates.updates
        updates.formUnion(stateUpdates.updates)
        return (stateUpdates.state, updates)
      }
  }

  deinit {
    cursorBlinkingTask?.cancel()
  }

  @discardableResult
  public func apiAsyncTask<T: Sendable>(_ body: @escaping @Sendable (API<ProcessChannel>) async throws -> T) async -> T? {
    await Task {
      do {
        return try await body(api)
      } catch {
        await alertsChannel.send(.init(error))
        return nil
      }
    }.value
  }

  public func apiTask(
    _ body: @escaping @Sendable (API<ProcessChannel>) async throws -> (some Sendable)?
  ) {
    Task {
      do {
        _ = try await body(api)
      } catch {
        await alertsChannel.send(.init(error))
      }
    }
  }

  public func reportOuterGrid(changedSizeTo size: IntegerSize) {
    guard size != previousReportedOuterGridSize else {
      return
    }
    previousReportedOuterGridSize = size

    guard outerGridSizeThrottlingTask == nil else {
      return
    }
    defer { previousReportedOuterGridSizeInstant = .now }

    let sincePrevious = previousReportedOuterGridSizeInstant.duration(to: .now)
    if sincePrevious > outerGridSizeThrottlingInterval {
      instance.reportOuterGrid(changedSizeTo: size)
    } else {
      outerGridSizeThrottlingTask = Task { [weak self] in
        guard let self else {
          return
        }

        do {
          try await Task
            .sleep(for: outerGridSizeThrottlingInterval - sincePrevious)

          instance
            .reportOuterGrid(changedSizeTo: previousReportedOuterGridSize!)
        } catch { }

        outerGridSizeThrottlingTask = nil
      }
    }
  }

  public func reportPumBounds(rectangle: IntegerRectangle) {
    //    guard rectangle != previousPumBounds else {
    //      return
    //    }
    //    previousPumBounds = rectangle
    //
    //    do {
    //      try instance.reportPumBounds(rectangle: rectangle)
    //    } catch {
    //      handleError(error)
    //    }
  }

  public func dumpState() -> String {
    var string = ""
    customDump(latestUIEventsBatch, to: &string)
    return string
  }

  public func dispatch(_ action: Action) {
    Task {
      await actionsChannel.send(action)
    }
  }
}
