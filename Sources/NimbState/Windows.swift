// SPDX-License-Identifier: MIT

import NimbCore
import NimbNeovim

@PublicInit
public struct FloatingWindow: Sendable, Identifiable {
  public enum Anchor: String, Sendable {
    case northWest = "NW"
    case northEast = "NE"
    case southWest = "SW"
    case southEast = "SE"
  }

  public var id: References.Window
  public var anchor: Anchor
  public var anchorGridID: Grid.ID
  public var anchorRow: Double
  public var anchorColumn: Double
  public var isFocusable: Bool

  /// The configured zindex. Kept for reference; `compositingIndex` is what
  /// actually decides stacking.
  public var zIndex: Int

  /// Neovim's `compindex`: the exact rendering order it has already worked
  /// out for the floats. The docs are explicit that a UI should render in
  /// this order rather than deriving one from zindex.
  public var compositingIndex: Int = 0
}

@PublicInit
public struct ExternalWindow: Sendable, Identifiable {
  public var id: References.Window
}
