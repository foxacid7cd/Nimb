// SPDX-License-Identifier: MIT

import Neovim
import SwiftUI

public extension EnvironmentValues {
  private struct NimsFontKey: EnvironmentKey {
    static let defaultValue = NimsFont(.monospacedSystemFont(ofSize: 12, weight: .regular))
  }

  var nimsFont: NimsFont {
    get {
      self[NimsFontKey.self]
    }
    set {
      self[NimsFontKey.self] = newValue
    }
  }
}
