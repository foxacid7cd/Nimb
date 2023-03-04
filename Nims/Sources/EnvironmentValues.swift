// SPDX-License-Identifier: MIT

import Neovim
import SwiftUI

public extension EnvironmentValues {
  private struct NimsFontKey: EnvironmentKey {
    static let defaultValue = NimsFont(
      NSFont(name: "SFMono Nerd Font Mono", size: 12) ??
        NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    )
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
