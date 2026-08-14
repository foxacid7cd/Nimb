// SPDX-License-Identifier: MIT

import Algorithms
import Collections
import Foundation
import NimbCore
import NimbNeovim
import NimbState

/// Nonisolated by design: dispatch and show are called from key monitors,
/// gesture handlers and the off-main updates loop alike, and the store owns no
/// mutable state of its own — the reducer's State lives as a local inside the
/// single task that drives it.
public nonisolated final class Store: Sendable {
  private enum PendingActions: Sendable {
    case single(any Action)
    case batch([any Action])
    case failure(any Error)
  }

  private actor PendingActionsState {
    private var remainingProducers: Int
    private var isFinished = false

    init(remainingProducers: Int) {
      self.remainingProducers = remainingProducers
    }

    func producerDidFinish() -> Bool {
      guard !isFinished else {
        return false
      }

      remainingProducers -= 1
      if remainingProducers == 0 {
        isFinished = true
        return true
      }

      return false
    }

    func finishOnFailure() -> Bool {
      guard !isFinished else {
        return false
      }

      isFinished = true
      return true
    }
  }

  public let updates: AsyncStream<(state: State, updates: State.Updates)>

  public let api: API<ProcessChannel>

  public let alerts: AsyncStream<Alert>

  private let actionsContinuation: AsyncStream<Action>.Continuation
  private let alertsContinuation: AsyncStream<Alert>.Continuation

  public init(api: API<ProcessChannel>, initialState: State) {
    self.api = api

    let actions: AsyncStream<Action>
    (actions, actionsContinuation) = AsyncStream.makeStream()

    (alerts, alertsContinuation) = AsyncStream.makeStream()

    let pendingActionsStream: AsyncStream<PendingActions>
    let pendingActionsContinuation: AsyncStream<PendingActions>.Continuation
    (pendingActionsStream, pendingActionsContinuation) = AsyncStream.makeStream()
    let pendingActionsState = PendingActionsState(remainingProducers: 2)

    let actionsTask = Task {
      for await action in actions {
        guard !Task.isCancelled else {
          return
        }
        pendingActionsContinuation.yield(.single(action))
      }

      if await pendingActionsState.producerDidFinish() {
        pendingActionsContinuation.finish()
      }
    }

    let neovimNotificationsTask = Task { [alertsContinuation] in
      do {
        for try await neovimNotificationsBatch in api.neovimNotifications {
          guard !Task.isCancelled else {
            return
          }

          var redrawActions = [any Action]()
          redrawActions.reserveCapacity(neovimNotificationsBatch.count)

          for notification in neovimNotificationsBatch {
            switch notification {
            case let .redraw(uiEvents):
              redrawActions.append(
                Actions.ApplyUIEvents(
                  uiEvents: uiEvents,
                ),
              )

            case let .nvimErrorEvent(event):
              alertsContinuation.yield("nvimErrorEvent received \(cd: event)")

            case let .nimbNotify(value):
              alertsContinuation.yield("nimbNotify received \(cd: value)")
            }
          }

          switch redrawActions.count {
          case 0:
            break

          case 1:
            pendingActionsContinuation.yield(.single(redrawActions[0]))

          default:
            pendingActionsContinuation.yield(.batch(redrawActions))
          }
        }
      } catch {
        if await pendingActionsState.finishOnFailure() {
          pendingActionsContinuation.yield(.failure(error))
          pendingActionsContinuation.finish()
        }
        return
      }

      if await pendingActionsState.producerDidFinish() {
        pendingActionsContinuation.finish()
      }
    }

    pendingActionsContinuation.onTermination = { _ in
      actionsTask.cancel()
      neovimNotificationsTask.cancel()
    }

    updates = AsyncStream<(state: State, updates: State.Updates)> { [alertsContinuation] continuation in
      Task { @StateActor in
        var state = initialState
        var updates = State.Updates()
        continuation.yield((state, updates))

        func apply(_ action: any Action) {
          let newUpdates = action.apply(to: &state) { error in
            alertsContinuation.yield(.init(error))
          }
          updates.formUnion(newUpdates)

          if updates.needFlush {
            continuation.yield((state, updates))
            updates = .init()
          }
        }

        for await pendingActions in pendingActionsStream {
          guard !Task.isCancelled else {
            return
          }

          switch pendingActions {
          case let .single(action):
            apply(action)

          case let .batch(batch):
            for action in batch {
              apply(action)
            }

          case let .failure(error):
            alertsContinuation.yield(.init(error))
            continuation.finish()
            return
          }
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
