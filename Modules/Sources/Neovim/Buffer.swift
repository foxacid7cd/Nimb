// SPDX-License-Identifier: MIT

import Tagged

public struct Buffer: Sendable, Identifiable {
  public var id: ID

  public typealias ID = Tagged<Self, References.Buffer>
}
