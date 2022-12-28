// SPDX-License-Identifier: MIT

import IdentifiedCollections
import Library
import Neovim
import Tagged

public struct State: Sendable, Equatable, Identifiable {
  public init(
    id: ID,
    font: Font? = nil,
    grids: IdentifiedArrayOf<Grid> = [],
    windows: IdentifiedArrayOf<Window> = []
  ) {
    self.id = id
    self.font = font
    self.grids = grids
    self.windows = windows
  }

  public typealias ID = Tagged<State, String>

  public struct Grid: Sendable, Equatable, Identifiable {
    public init(id: ID, cells: TwoDimensionalArray<Cell>) {
      self.id = id
      self.cells = cells
    }

    public typealias ID = Tagged<Grid, Int>

    public var id: ID
    public var cells: TwoDimensionalArray<Cell>
  }

  public struct Window: Sendable, Equatable, Identifiable {
    public init(reference: References.Window, gridID: Grid.ID, frame: IntegerRectangle) {
      self.reference = reference
      self.gridID = gridID
      self.frame = frame
    }

    public var reference: References.Window
    public var gridID: Grid.ID
    public var frame: IntegerRectangle

    public var id: References.Window {
      reference
    }
  }

  public var id: ID
  public var font: Font?
  public var grids: IdentifiedArrayOf<Grid>
  public var windows: IdentifiedArrayOf<Window>

  public var outerGrid: Grid? {
    get {
      grids[id: .outer]
    }
    set {
      grids[id: .outer] = newValue
    }
  }
}

public extension State.Grid.ID {
  static var outer: Self {
    1
  }

  var isOuter: Bool {
    self == .outer
  }
}
