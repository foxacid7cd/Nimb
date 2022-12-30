// SPDX-License-Identifier: MIT

import SwiftUI

extension EnvironmentValues {
  private struct CursorPhaseKey: EnvironmentKey {
    static let defaultValue = true
  }

  var cursorPhase: Bool {
    get {
      self[CursorPhaseKey.self]
    }
    set {
      self[CursorPhaseKey.self] = newValue
    }
  }
}
