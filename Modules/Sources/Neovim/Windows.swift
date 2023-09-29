// SPDX-License-Identifier: MIT

import Library

@PublicInit
public struct Window: Sendable, Identifiable {
  public var id: References.Window
  public var frame: IntegerRectangle
  public var zIndex: Int
}

@PublicInit
public struct FloatingWindow: Sendable, Identifiable {
  public var id: Window.ID
  public var anchor: Anchor
  public var anchorGridID: Grid.ID
  public var anchorRow: Double
  public var anchorColumn: Double
  public var isFocusable: Bool
  public var zIndex: Int

  public enum Anchor: String, Sendable {
    case northWest = "NW"
    case northEast = "NE"
    case southWest = "SW"
    case southEast = "SE"
  }
}

@PublicInit
public struct ExternalWindow: Sendable, Identifiable {
  public var id: Window.ID
}
