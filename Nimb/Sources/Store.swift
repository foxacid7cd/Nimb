// SPDX-License-Identifier: MIT

import Algorithms
import Collections
import ConcurrencyExtras
import CustomDump
import Foundation

public final class Store: Sendable {
  public let updates: AsyncStream<(state: State, updates: State.Updates)>

  public let api: API<ProcessChannel>

  public let alerts: AsyncStream<Alert>

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

  private let actionsContinuation: AsyncStream<Action>.Continuation
  private let alertsContinuation: AsyncStream<Alert>.Continuation

  public init(api: API<ProcessChannel>, initialState: State) {
    self.api = api

    let actions: AsyncStream<Action>
    (actions, actionsContinuation) = AsyncStream.makeStream()

    (alerts, alertsContinuation) = AsyncStream.makeStream()

    let applyUIEventsActions = api.neovimNotifications
      .compactMap { [
        alertsContinuation
      ] neovimNotificationsBatch in
        var actionsAccumulator = [Action]()

        for notification in neovimNotificationsBatch {
          switch notification {
          case let .redraw(uiEvents):
            actionsAccumulator
              .append(
                Actions
                  .ApplyUIEvents(
                    uiEvents: uiEvents
                  )
              )

          case let .nvimErrorEvent(event):
            alertsContinuation.yield("nvimErrorEvent received \(cd: event)")

          case let .nimbNotify(value):
            alertsContinuation.yield("nimbNotify received \(cd: value)")
          }
        }

        return actionsAccumulator.isEmpty ? nil : actionsAccumulator
      }

    let allActions = AsyncThrowingStream<[Action], any Error> { continuation in
      let task = Task {
        await withTaskGroup(of: (any Error)?.self) { group in
          group.addTask {
            for await action in actions {
              guard !Task.isCancelled else {
                return nil
              }
              continuation.yield([action])
            }
            return nil
          }
          group.addTask {
            do {
              for try await action in applyUIEventsActions {
                guard !Task.isCancelled else {
                  return nil
                }
                continuation.yield(action)
              }
              return nil
            } catch {
              return error
            }
          }
          for await error in group {
            if let error {
              continuation.finish(throwing: error)
              return
            }
          }
          continuation.finish()
        }
      }
      continuation.onTermination = { _ in
        task.cancel()
      }
    }

    updates = AsyncStream<(state: State, updates: State.Updates)> { [alertsContinuation] continuation in
      Task {
        var state = initialState
        var updates = State.Updates()
        continuation.yield((state, updates))

        do {
          for try await actions in allActions {
            guard !Task.isCancelled else {
              return
            }

            for action in actions {
              let newUpdates = action.apply(to: &state) { error in
                alertsContinuation.yield(.init(error))
              }
              updates.formUnion(newUpdates)

              if updates.needFlush {
                continuation.yield((state, updates))
                updates = .init()
              }
            }
          }
        } catch {
          alertsContinuation.yield(.init(error))
        }

        continuation.finish()
      }
    }
  }

  public nonisolated func dispatch(_ action: Action) {
    actionsContinuation.yield(action)
  }

  public nonisolated func show(alert: Alert) {
    alertsContinuation.yield(alert)
  }
}
