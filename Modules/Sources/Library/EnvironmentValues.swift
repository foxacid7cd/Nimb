// SPDX-License-Identifier: MIT

import SwiftUI

public extension EnvironmentValues {
  private struct NimsAppearanceKey: EnvironmentKey {
    static let defaultValue = NimsAppearance.defaultValue
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
