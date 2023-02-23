// SPDX-License-Identifier: MIT

import SwiftUI

public extension EnvironmentValues {
  private struct NimsAppearanceKey: EnvironmentKey {
    static let defaultValue = NimsAppearance(
      font: .init(.monospacedSystemFont(ofSize: 12, weight: .regular)),
      highlights: [],
      defaultForegroundColor: .init(rgb: 0xFFFFFF),
      defaultBackgroundColor: .init(rgb: 0x000000),
      defaultSpecialColor: .init(rgb: 0xFF0000)
    )
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
