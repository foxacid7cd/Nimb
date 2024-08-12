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

  public let api: API<ProcessChannel>

//    private func startCursorBlinkingTask() {
//      guard let cursorStyle = _state.currentCursorStyle else {
//        return
//      }
//      if
//        let blinkWait = cursorStyle.blinkWait,
//        blinkWait > 0,
//        let blinkOff = cursorStyle.blinkOff,
//        blinkOff > 0,
//        let blinkOn = cursorStyle.blinkOn,
//        blinkOn > 0
//      {
//        cursorBlinkingTask = Task {
//          do {
//            try await Task.sleep(for: .milliseconds(blinkWait))
//
//            while true {
//              dispatch(Actions.SetCursorBlinkingPhase(value: false))
//              try await Task.sleep(for: .milliseconds(blinkOff))
//
//              dispatch(Actions.SetCursorBlinkingPhase(value: true))
//              try await Task.sleep(for: .milliseconds(blinkOn))
//            }
//          } catch { }
//        }
//      }
//    }

  private let actionsChannel = AsyncChannel<Action>()
  private let alertsChannel = AsyncChannel<Alert>()

  public var alerts: AsyncStream<Alert> {
    alertsChannel.buffer(policy: .unbounded).eraseToStream()
  }

  public init(api: API<ProcessChannel>) {
    self.api = api

    let initialState = State(debug: UserDefaults.standard.debug, font: UserDefaults.standard.appKitFont.map(Font.init) ?? .init())

    let applyUIEventsActions = api.neovimNotifications
      .compactMap { [alertsChannel] neovimNotificationsBatch in
        var actions = [Action]()

        for notification in neovimNotificationsBatch {
          switch notification {
          case let .redraw(uiEvents):
            actions.append(Actions.ApplyUIEvents(uiEvents: uiEvents))
          case let .nvimErrorEvent(event):
            await alertsChannel.send("nvimErrorEvent received \(cd: event)")
          case let .nimbNotify(value):
            await alertsChannel.send("nimbNotify received \(cd: value)")
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
      .throttle(for: .milliseconds(1000 / 120), clock: .continuous) { previous, latest in
        var state = previous.state
        state.apply(updates: latest.updates, from: latest.state)
        var updates = previous.updates
        updates.formUnion(latest.updates)
        return (state, updates)
      }
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
    _ body: @escaping @Sendable (API<ProcessChannel>) async throws -> Void
  ) {
    Task {
      do {
        _ = try await body(api)
      } catch {
        await alertsChannel.send(.init(error))
      }
    }
  }

  public func dispatch(_ action: Action) {
    Task {
      await actionsChannel.send(action)
    }
  }
}
