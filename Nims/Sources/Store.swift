// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import Foundation
import Library

@MainActor
final class Store: Sendable {
  init(instance: Instance, font: NimsFont) {
    self.instance = instance
    let state = State(instanceState: .init(font: font))
    self.state = state
    backgroundState = state

    task = Task { @NeovimActor [weak self] in
      do {
        for try await instanceStateUpdates in instance {
          guard let self else {
            return
          }

          try Task.checkCancellation()

          let state = instance.state
          self.backgroundState.instanceState = state

          if instanceStateUpdates.isMsgShowsUpdated, !self.backgroundState.msgShows.isEmpty {
            self.hideMsgShowsTask?.cancel()
            self.hideMsgShowsTask = nil

            self.backgroundState.isMsgShowsDismissed = false
            Task { @MainActor in
              self.state.isMsgShowsDismissed = false
            }
          }

          Task { @MainActor in
            self.state.instanceState = state
            await self.sendStateUpdates(.init(instanceStateUpdates: instanceStateUpdates))
          }
        }
      } catch is CancellationError {
      } catch {
        assertionFailure(error)
      }
    }
  }

  deinit {
    task?.cancel()
    hideMsgShowsTask?.cancel()
  }

  let instance: Instance
  private(set) var state: State

  var font: NimsFont {
    state.font
  }

  var appearance: Appearance {
    state.appearance
  }

  func set(font: NimsFont) {
    Task { @NeovimActor in
      backgroundState.instanceState.font = font
      Task { @MainActor in
        state.instanceState.font = font
        await sendStateUpdates(.init(instanceStateUpdates: .init(isFontUpdated: true)))
      }
    }
  }

  func scheduleHideMsgShowsIfPossible() {
    Task { @NeovimActor in
      if !backgroundState.hasModalMsgShows, !backgroundState.isMsgShowsDismissed, hideMsgShowsTask == nil {
        hideMsgShowsTask = Task { [weak self] in
          do {
            try await Task.sleep(for: .milliseconds(500))

            guard let self else {
              return
            }

            hideMsgShowsTask = nil
            backgroundState.isMsgShowsDismissed = true
            Task { @MainActor in
              self.state.isMsgShowsDismissed = true
              await self.sendStateUpdates(.init(isMsgShowsDismissedUpdated: true))
            }
          } catch {}
        }
      }
    }
  }

  private let (sendStateUpdates, stateUpdates) = AsyncChannel<State.Updates>.pipe(
    bufferingPolicy: .unbounded
  )

  @NeovimActor
  private var backgroundState: State

  private var task: Task<Void, Never>?

  @NeovimActor
  private var hideMsgShowsTask: Task<Void, Never>?
}

extension Store: AsyncSequence {
  typealias Element = State.Updates

  nonisolated func makeAsyncIterator() -> AsyncStream<State.Updates>.AsyncIterator {
    stateUpdates.makeAsyncIterator()
  }
}
