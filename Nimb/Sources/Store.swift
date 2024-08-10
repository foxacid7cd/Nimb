// SPDX-License-Identifier: MIT

import Algorithms
import AsyncAlgorithms
import Collections
import ConcurrencyExtras
import CustomDump
import Foundation

@MainActor
public class Store: Sendable {
  public let updates: AsyncStream<(state: State, updates: State.Updates)>

  public let alertMessages = AsyncChannel<AlertMessage>()

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
  fileprivate let handleErrorMessage: @Sendable (String) -> Void
  fileprivate let handleError: @Sendable (any Error) -> Void

  private let apiTasksChannel = AsyncChannel< @Sendable (API<ProcessChannel>) async throws -> Any? > ()

  private let actionsChannel = AsyncChannel<Action>()
  private var cursorBlinkingTask: Task<Void, Never>?
  private var previousReportedOuterGridSize: IntegerSize?
  private var previousReportedOuterGridSizeInstant = ContinuousClock().now
  private var outerGridSizeThrottlingTask: Task<Void, Never>?
  private let outerGridSizeThrottlingInterval: Duration = .milliseconds(1000 / 120)
  private var previousMouseMove: (modifier: String, gridID: Grid.ID, point: IntegerPoint)?
  private var latestUIEventsBatch = [UIEvent]()

  public var api: API<ProcessChannel> {
    instance.api
  }

  public init(instance: Instance, debug: State.Debug, font: Font) {
    self.instance = instance

    handleErrorMessage = { [alertMessages] message in
      Task {
        await alertMessages.send(.init(content: message))
      }
    }
    handleError = { [alertMessages] error in
      Task {
        await alertMessages.send(.init(error))
      }
    }

    let initialState = State(debug: debug, font: font)

    typealias StateAndUpdates = (state: State, updates: State.Updates)

    let applyUIEventsActions = instance.api.neovimNotifications
      .compactMap { [handleErrorMessage] neovimNotificationsBatch in
        var actions = [Action]()

        for notification in neovimNotificationsBatch {
          switch notification {
          case let .redraw(uiEvents):
            actions.append(Actions.ApplyUIEvents(uiEvents: uiEvents))
          case let .nvimErrorEvent(event):
            handleErrorMessage("nvimErrorEvent received \(event)")
          case let .nimbNotify(value):
            handleErrorMessage("nimbNotify received \(value)")
          }
        }

        return actions.isEmpty ? nil : actions
      }
      .flatMap(\.async)

    updates = AsyncStream(
      merge(actionsChannel, applyUIEventsActions)
        .buffer(policy: .unbounded)
        .reductions(into: (state: initialState, updates: State.Updates())) { [handleError] result, action in
          if result.updates.needFlush {
            result.updates = State.Updates(needFlush: false)
          }
          let updates = await action.apply(to: &result.state, handleError: handleError)
          result.updates.formUnion(updates)
        }
        .filter(\.updates.needFlush)
//        ._throttle(for: .milliseconds(1000 / 120), clock: .continuous) { (accum: StateAndUpdates?, new: StateAndUpdates) in
//          if let accum {
//            var updates = accum.updates
//            updates.formUnion(new.updates)
//            var _state = accum.state
//            _state.apply(updates: new.updates, from: new.state)
//            return (new.state, updates)
//          } else {
//            return new
//          }
//        }
    )
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
        handleError(error)
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
        handleError(error)
      }
    }
  }

  public func reportPopupmenuItemSelected(atIndex index: Int, isFinish: Bool) {
    do {
      try instance.reportPopupmenuItemSelected(
        atIndex: index,
        isFinish: isFinish
      )
    } catch {
      handleError(error)
    }
  }

  public func reportTablineBufferSelected(withID id: Buffer.ID) {
    do {
      try instance.reportTablineBufferSelected(withID: id)
    } catch {
      handleError(error)
    }
  }

  public func reportTablineTabpageSelected(withID id: Tabpage.ID) {
    do {
      try instance.reportTablineTabpageSelected(withID: id)
    } catch {
      handleError(error)
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

  public func reportPaste(text: String) {
    do {
      try instance.reportPaste(text: text)
    } catch {
      handleError(error)
    }
  }

  public func close() async {
    do {
      try await instance.close()
    } catch {
      handleError(error)
    }
  }

  public func quitAll() async {
    do {
      try await instance.quitAll()
    } catch {
      handleError(error)
    }
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

@PublicInit
public struct AlertMessage: Sendable {
  public var content: String

  public init(_ error: Error) {
    content =
      if let error = error as? NimbNeovimError {
        error.errorMessages.joined(separator: "\n")
      } else if let error = error as? NeovimError {
        String(customDumping: error.raw)
      } else {
        String(customDumping: error)
      }
  }
}
