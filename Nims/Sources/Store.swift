// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import Foundation
import Library

@MainActor
final class Store: Sendable {
  init(instance: Instance, font: NimsFont) {
    self.instance = instance
    let state = State(font: font)
    self.state = state
    backgroundState = state

    Task { @NeovimActor [weak self] in
      self?.stateUpdatesTask = Task {
        do {
          for try await instanceStateUpdates in instance {
            guard let self, !Task.isCancelled else {
              return
            }

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

            if instanceStateUpdates.isCursorUpdated {
              self.resetCursorBlinkingTask()
            }
          }
        } catch {
          assertionFailure(error)
        }
      }

      self?.resetCursorBlinkingTask()
    }
  }

  deinit {
    Task { @NeovimActor in
      stateUpdatesTask?.cancel()
      cursorBlinkingTask?.cancel()
      hideMsgShowsTask?.cancel()
    }
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
      backgroundState.font = font
      Task { @MainActor in
        state.font = font
        await sendStateUpdates(.init(isFontUpdated: true))
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

  @NeovimActor
  private var stateUpdatesTask: Task<Void, Never>?

  @NeovimActor
  private var cursorBlinkingTask: Task<Void, Never>?

  @NeovimActor
  private var hideMsgShowsTask: Task<Void, Never>?

  @NeovimActor
  private func resetCursorBlinkingTask() {
    cursorBlinkingTask?.cancel()

    if !backgroundState.cursorBlinkingPhase {
      backgroundState.cursorBlinkingPhase = true
      Task { @MainActor in
        self.state.cursorBlinkingPhase = true
        await sendStateUpdates(.init(isCursorBlinkingPhaseUpdated: true))
      }
    }

    if
      backgroundState.cmdlines.dictionary.isEmpty,
      let cursorStyle = backgroundState.currentCursorStyle,
      let blinkWait = cursorStyle.blinkWait, blinkWait > 0,
      let blinkOff = cursorStyle.blinkOff, blinkOff > 0,
      let blinkOn = cursorStyle.blinkOn, blinkOn > 0
    {
      cursorBlinkingTask = Task { @NeovimActor [weak self] in
        do {
          try await Task.sleep(for: .milliseconds(blinkWait))

          while true {
            guard let self else {
              return
            }
            self.backgroundState.cursorBlinkingPhase = false
            Task { @MainActor in
              self.state.cursorBlinkingPhase = false
              await self.sendStateUpdates(.init(isCursorBlinkingPhaseUpdated: true))
            }

            try await Task.sleep(for: .milliseconds(blinkOff))

            self.backgroundState.cursorBlinkingPhase = true
            Task { @MainActor in
              self.state.cursorBlinkingPhase = true
              await self.sendStateUpdates(.init(isCursorBlinkingPhaseUpdated: true))
            }

            try await Task.sleep(for: .milliseconds(blinkOn))
          }
        } catch {}
      }
    }
  }
}

extension Store: AsyncSequence {
  typealias Element = State.Updates

  nonisolated func makeAsyncIterator() -> AsyncStream<State.Updates>.AsyncIterator {
    stateUpdates.makeAsyncIterator()
  }
}
