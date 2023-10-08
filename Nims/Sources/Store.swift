// SPDX-License-Identifier: MIT

import Foundation
import Library

@MainActor
@dynamicMemberLookup
final class Store {
  init(instance: Instance, font: NimsFont, stateUpdatesObserver: @escaping @MainActor (State.Updates) -> Void) {
    self.instance = instance
    self.state = .init(font: font)
    self.stateUpdatesObserver = stateUpdatesObserver

    let instanceStateUpdatesStream = instance.stateUpdatesStream()
    observeCursorUpdatesTask = Task { @MainActor [weak self] in
      for await instanceStateUpdates in instanceStateUpdatesStream {
        guard let self, !Task.isCancelled else {
          break
        }

        self.state.instanceState = instance.state

        if instanceStateUpdates.isCursorUpdated {
          self.resetCursorBlinkingTask()
        }

        if instanceStateUpdates.isMsgShowsUpdated, !self.state.msgShows.isEmpty {
          self.hideMsgShowsTask?.cancel()
          self.hideMsgShowsTask = nil
          self.state.isMsgShowsDismissed = false
        }

        stateUpdatesObserver(.init(instanceStateUpdates: instanceStateUpdates))
      }
    }

    resetCursorBlinkingTask()
  }

  deinit {
    observeCursorUpdatesTask?.cancel()
  }

  let instance: Instance
  private(set) var state: State

  func set(font: NimsFont) {
    state.font = font
    stateUpdatesObserver(.init(isFontUpdated: true))
  }

  func scheduleHideMsgShowsIfPossible() {
    if !state.hasModalMsgShows, !state.isMsgShowsDismissed, hideMsgShowsTask == nil {
      hideMsgShowsTask = Task { [weak self] in
        try? await Task.sleep(for: .milliseconds(500))

        guard !Task.isCancelled, let self else {
          return
        }

        hideMsgShowsTask = nil
        state.isMsgShowsDismissed = true
        stateUpdatesObserver(.init(isMsgShowsDismissedUpdated: true))
      }
    }
  }

  subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
    state[keyPath: keyPath]
  }

  private var observeCursorUpdatesTask: Task<Void, Never>?
  private var cursorBlinkingTask: Task<Void, Never>?
  private let stateUpdatesObserver: @MainActor (State.Updates) -> Void
  private var hideMsgShowsTask: Task<Void, Never>?

  private func resetCursorBlinkingTask() {
    cursorBlinkingTask?.cancel()

    if !state.cursorBlinkingPhase {
      state.cursorBlinkingPhase = true
      stateUpdatesObserver(.init(isCursorBlinkingPhaseUpdated: true))
    }

    if
      self.cmdlines.dictionary.isEmpty,
      let cursorStyle = self.currentCursorStyle,
      let blinkWait = cursorStyle.blinkWait, blinkWait > 0,
      let blinkOff = cursorStyle.blinkOff, blinkOff > 0,
      let blinkOn = cursorStyle.blinkOn, blinkOn > 0
    {
      cursorBlinkingTask = Task { @MainActor [weak self] in
        try? await Task.sleep(for: .milliseconds(blinkWait))

        while true {
          guard !Task.isCancelled else {
            return
          }
          self?.state.cursorBlinkingPhase = false
          self?.stateUpdatesObserver(.init(isCursorBlinkingPhaseUpdated: true))

          try? await Task.sleep(for: .milliseconds(blinkOff))

          guard !Task.isCancelled else {
            return
          }
          self?.state.cursorBlinkingPhase = true
          self?.stateUpdatesObserver(.init(isCursorBlinkingPhaseUpdated: true))

          try? await Task.sleep(for: .milliseconds(blinkOn))
        }
      }
    }
  }
}
