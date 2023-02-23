// SPDX-License-Identifier: MIT

import Dependencies

public extension DependencyValues {
  private struct DrawRunsProviderKey: DependencyKey {
    static let liveValue: DrawRunsProvider = .init()
    static let previewValue: DrawRunsProvider = .init()
    static let testValue: DrawRunsProvider = .init()
  }

  var drawRunsProvider: DrawRunsProvider {
    get {
      self[DrawRunsProviderKey.self]
    }
    set {
      self[DrawRunsProviderKey.self] = newValue
    }
  }
}
