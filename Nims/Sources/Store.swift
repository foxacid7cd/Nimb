// SPDX-License-Identifier: MIT

import Foundation
import Library

@MainActor
final class Store: Sendable {
  init(instance: Instance, font: NimsFont, stateUpdatesObserver: @escaping @Sendable @MainActor (Store, State.Updates) -> Void) {
    self.instance = instance
    let state = State(font: font)
    self.state = state
    backgroundState = state
    self.stateUpdatesObserver = stateUpdatesObserver

    Task { @NeovimActor [weak self] in
      let instanceStateUpdatesStream = instance.stateUpdatesStream()
      self?.stateUpdatesTask = Task {
        for await instanceStateUpdates in instanceStateUpdatesStream {
          guard let self, !Task.isCancelled else {
            break
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
            stateUpdatesObserver(self, .init(instanceStateUpdates: instanceStateUpdates))
          }

          if instanceStateUpdates.isCursorUpdated {
            self.resetCursorBlinkingTask()
          }
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
        await stateUpdatesObserver(self, .init(isFontUpdated: true))
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
              await self.stateUpdatesObserver(self, .init(isMsgShowsDismissedUpdated: true))
            }
          } catch {}
        }
      }
    }
  }

  @NeovimActor
  private var backgroundState: State

  private let stateUpdatesObserver: @Sendable @MainActor (Store, State.Updates) async -> Void

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
        await stateUpdatesObserver(self, .init(isCursorBlinkingPhaseUpdated: true))
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
              await self.stateUpdatesObserver(self, .init(isCursorBlinkingPhaseUpdated: true))
            }

            try await Task.sleep(for: .milliseconds(blinkOff))

            self.backgroundState.cursorBlinkingPhase = true
            Task { @MainActor in
              self.state.cursorBlinkingPhase = true
              await self.stateUpdatesObserver(self, .init(isCursorBlinkingPhaseUpdated: true))
            }

            try await Task.sleep(for: .milliseconds(blinkOn))
          }
        } catch {}
      }
    }
  }
}
