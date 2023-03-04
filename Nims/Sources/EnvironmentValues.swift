// SPDX-License-Identifier: MIT

import Neovim
import SwiftUI

extension EnvironmentValues {
  private struct NimsFontKey: EnvironmentKey {
    static let defaultValue = NimsFont(
      NSFont(name: "SFMono Nerd Font Mono", size: 12) ??
        NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    )
  }

  private struct AppearanceKey: EnvironmentKey {
    static let defaultValue = Appearance()
  }

  var nimsFont: NimsFont {
    get {
      self[NimsFontKey.self]
    }
    set {
      self[NimsFontKey.self] = newValue
    }
  }

  var appearance: Appearance {
    get {
      self[AppearanceKey.self]
    }
    set {
      self[AppearanceKey.self] = newValue
    }
  }
}
