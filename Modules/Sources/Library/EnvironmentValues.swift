// SPDX-License-Identifier: MIT

import SwiftUI

public extension EnvironmentValues {
  private struct NimsAppearanceKey: EnvironmentKey {
    static let defaultValue: NimsAppearance = {
      let nsFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
      return .init(
        font: .init(nsFont),
        cellWidth: nsFont.makeCellWidth(),
        cellHeight: nsFont.makeCellHeight(),
        highlights: [],
        defaultForegroundColor: .init(rgb: 0xFFFFFF),
        defaultBackgroundColor: .init(rgb: 0x000000),
        defaultSpecialColor: .init(rgb: 0xFF0000)
      )
    }()
  }

  var nimsAppearance: NimsAppearance {
    get {
      self[NimsAppearanceKey.self]
    }
    set {
      self[NimsAppearanceKey.self] = newValue
    }
  }
}
