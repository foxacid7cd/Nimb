// SPDX-License-Identifier: MIT

import Foundation
import Neovim

@MainActor
final class CursorBlinker {
  deinit {
    task?.cancel()
  }

  private(set) var cursorBlinkingPhase = true
  var observer: (@MainActor () -> Void)?

  func cursorUpdated(state: Neovim.State) {
    task?.cancel()

    if !cursorBlinkingPhase {
      cursorBlinkingPhase = true
      observer?()
    }

    if
      state.cmdlines.dictionary.isEmpty,
      let cursorStyle = state.currentCursorStyle,
      let blinkWait = cursorStyle.blinkWait, blinkWait > 0,
      let blinkOff = cursorStyle.blinkOff, blinkOff > 0,
      let blinkOn = cursorStyle.blinkOn, blinkOn > 0
    {
      task = Task { @MainActor [weak self] in
        try? await Task.sleep(for: .milliseconds(blinkWait))

        while !Task.isCancelled {
          self?.cursorBlinkingPhase = false
          self?.observer?()

          try? await Task.sleep(for: .milliseconds(blinkOff))

          self?.cursorBlinkingPhase = true
          self?.observer?()

          try? await Task.sleep(for: .milliseconds(blinkOn))
        }
      }
    }
  }

  private var task: Task<Void, Never>?
}
