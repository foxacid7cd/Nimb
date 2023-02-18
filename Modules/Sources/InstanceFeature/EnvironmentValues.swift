// SPDX-License-Identifier: MIT

import SwiftUI

public extension EnvironmentValues {
  private struct DrawRunCacheKey: EnvironmentKey {
    static let defaultValue = DrawRunCache()
  }

  var drawRunCache: DrawRunCache {
    get {
      self[DrawRunCacheKey.self]
    }
    set {
      self[DrawRunCacheKey.self] = newValue
    }
  }
}
