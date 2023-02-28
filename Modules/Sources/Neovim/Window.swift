// SPDX-License-Identifier: MIT

import Library
import Tagged

public struct Window: Sendable, Identifiable {
  public var id: ID
  public var frame: IntegerRectangle
  public var zIndex: Int

  public typealias ID = Tagged<Self, References.Window>
}

public struct FloatingWindow: Sendable, Identifiable {
  public var id: ID
  public var anchor: Anchor
  public var anchorGridID: Grid.ID
  public var anchorRow: Double
  public var anchorColumn: Double
  public var isFocusable: Bool
  public var zIndex: Int

  public typealias ID = Window.ID

  public enum Anchor: String, Sendable {
    case northWest = "NW"
    case northEast = "NE"
    case southWest = "SW"
    case southEast = "SE"
  }
}

public struct ExternalWindow: Sendable, Identifiable {
  public var id: ID

  public typealias ID = Window.ID
}
