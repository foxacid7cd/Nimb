// SPDX-License-Identifier: MIT

import Foundation
import Neovim

@MainActor
final class CursorBlinker {
  private(set) var cursorBlinkingPhase = true
  var observer: (@MainActor () -> Void)?

  private var task: Task<Void, Never>?

  deinit {
    task?.cancel()
  }

  func set(cursor: Cursor) {
    task?.cancel()

    if !cursorBlinkingPhase {
      cursorBlinkingPhase = true
      observer?()
    }

    task = Task { @MainActor [weak self] in
      try? await Task.sleep(for: .seconds(1))

      while !Task.isCancelled {
        self?.cursorBlinkingPhase.toggle()
        self?.observer?()

        try? await Task.sleep(for: .milliseconds(500))
      }
    }
  }
}
