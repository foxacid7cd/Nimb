// SPDX-License-Identifier: MIT

import Algorithms
import Collections
import Foundation
import NimbCore
import NimbNeovim
import NimbState
import Synchronization

/// Nonisolated by design: it is called from key monitors, gesture handlers and
/// the off-main updates loop alike, and owns no mutable state of its own.
public final nonisolated class Store: Sendable {
  private struct AcknowledgedAction: Action {
    var action: any Action
    var continuation: CheckedContinuation<Void, Never>

    func apply(to state: inout State, handleError: @Sendable (Error) -> Void) -> State.Updates {
      let updates = action.apply(to: &state, handleError: handleError)
      continuation.resume()
      return updates
    }
  }

  private enum PendingActions: Sendable {
    case single(any Action)
    case batch([any Action])
    case failure(any Error)
  }

  /// Counts the two producers down so whichever finishes last closes the
  /// stream. A lock rather than an actor, to avoid suspending twice.
  private final class PendingActionsState: Sendable {
    private struct Storage {
      var remainingProducers: Int
      var isFinished = false
    }

    private let storage: Mutex<Storage>

    init(remainingProducers: Int) {
      storage = .init(.init(remainingProducers: remainingProducers))
    }

    func producerDidFinish() -> Bool {
      storage.withLock { storage in
        guard !storage.isFinished else {
          return false
        }

        storage.remainingProducers -= 1
        if storage.remainingProducers == 0 {
          storage.isFinished = true
          return true
        }

        return false
      }
    }

    func finishOnFailure() -> Bool {
      storage.withLock { storage in
        guard !storage.isFinished else {
          return false
        }

        storage.isFinished = true
        return true
      }
    }
  }

  public let updates: AsyncStream<(state: State, updates: State.Updates)>

  public let api: API

  public let alerts: AsyncStream<Alert>

  private let actionsContinuation: AsyncStream<Action>.Continuation
  private let alertsContinuation: AsyncStream<Alert>.Continuation

  public init(api: API, initialState: State) {
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

      if pendingActionsState.producerDidFinish() {
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
        if pendingActionsState.finishOnFailure() {
          pendingActionsContinuation.yield(.failure(error))
          pendingActionsContinuation.finish()
        }
        return
      }

      if pendingActionsState.producerDidFinish() {
        pendingActionsContinuation.finish()
      }
    }

    pendingActionsContinuation.onTermination = { _ in
      actionsTask.cancel()
      neovimNotificationsTask.cancel()
    }

    // The debug flag puts the reducer back on main, so it and the render walk
    // time as one serialised number instead of two overlapping ones.
    let isReducingOnMainThread = initialState.debug.isReducingOnMainThreadEnabled

    updates = AsyncStream<(state: State, updates: State.Updates)> { [alertsContinuation] continuation in
      if isReducingOnMainThread {
        Task { @MainActor in
          await Self.runReducer(
            initialState: initialState,
            pendingActions: pendingActionsStream,
            continuation: continuation,
            alertsContinuation: alertsContinuation,
          )
        }
      } else {
        Task {
          await Self.runReducer(
            initialState: initialState,
            pendingActions: pendingActionsStream,
            continuation: continuation,
            alertsContinuation: alertsContinuation,
          )
        }
      }
    }
  }

  /// Applies actions to State until the action stream ends. `isolation` makes
  /// this adopt the caller's actor, so one body serves both spawn sites.
  private static func runReducer(
    isolation: isolated (any Actor)? = #isolation,
    initialState: State,
    pendingActions: AsyncStream<PendingActions>,
    continuation: AsyncStream<(state: State, updates: State.Updates)>.Continuation,
    alertsContinuation: AsyncStream<Alert>.Continuation,
  ) async {
    var state = initialState
    var updates = State.Updates()
    continuation.yield((state, updates))

    // Whether Neovim is part way through sending a frame. Only the redraw
    // batch carrying flush completes one.
    var isRedrawFrameIncomplete = false

    func apply(_ action: any Action) {
      let newUpdates = measuringRenderStage("reduce", .reduce) {
        action.apply(to: &state) { error in
          alertsContinuation.yield(.init(error))
        }
      }
      updates.formUnion(newUpdates)

      if newUpdates.isFromRedrawBatch {
        isRedrawFrameIncomplete = !newUpdates.needFlush
      }

      // Actions from outside the redraw protocol also ask for a render, but
      // must wait for Neovim to finish the frame rather than halve it.
      guard updates.needFlush, !isRedrawFrameIncomplete else {
        return
      }
      continuation.yield((state, updates))
      updates = .init()
    }

    for await pendingActions in pendingActions {
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

  public nonisolated func dispatch(_ action: Action) {
    actionsContinuation.yield(action)
  }

  public nonisolated func dispatchAndWait(_ action: some Action) async {
    await withCheckedContinuation { continuation in
      let result = actionsContinuation.yield(AcknowledgedAction(
        action: action,
        continuation: continuation,
      ))
      if case .terminated = result {
        continuation.resume()
      }
    }
  }

  public nonisolated func show(alert: Alert) {
    alertsContinuation.yield(alert)
  }
}
