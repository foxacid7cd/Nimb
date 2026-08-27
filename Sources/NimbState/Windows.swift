// SPDX-License-Identifier: MIT

import NimbCore
import NimbNeovim

@PublicInit
public struct FloatingWindow: Sendable, Identifiable {
  public var id: References.Window

  /// The grid this float hangs off. Only used to place it in the grid
  /// hierarchy — positioning comes from `screenRow`/`screenColumn`.
  public var anchorGridID: Grid.ID

  /// Where Neovim has decided this float goes, in cells, relative to the
  /// screen. Already clamped, so anchor/anchor_row/anchor_col are ignored.
  public var screenRow: Int
  public var screenColumn: Int

  public var isFocusable: Bool

  /// The configured zindex. Kept for reference; `compositingIndex` is what
  /// actually decides stacking.
  public var zIndex: Int

  /// Neovim's `compindex`. The docs are explicit that a UI should render in
  /// this order rather than deriving one from zindex.
  public var compositingIndex: Int = 0
}

@PublicInit
public struct ExternalWindow: Sendable, Identifiable {
  public var id: References.Window
}
