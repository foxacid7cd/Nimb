// SPDX-License-Identifier: MIT

import Tagged

public struct Highlight: Sendable, Equatable, Identifiable {
  public init(id: ID) {
    self.id = id
  }

  public typealias ID = Tagged<Highlight, Int>

  public var id: ID
}

public extension Highlight.ID {
  static var `default`: Self {
    0
  }

  var isDefault: Bool {
    self == .default
  }
}
