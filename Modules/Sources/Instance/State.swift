// SPDX-License-Identifier: MIT

import IdentifiedCollections
import Library
import Neovim
import Tagged

public struct State: Sendable, Equatable, Identifiable {
  public init(id: State.ID, flushed: State.Snapshot? = nil, current: State.Snapshot = .init()) {
    self.id = id
    self.flushed = flushed
    self.current = current
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
    public init(reference: References.Window, gridID: Grid.ID, frame: IntegerRectangle, isHidden: Bool) {
      self.reference = reference
      self.gridID = gridID
      self.frame = frame
      self.isHidden = isHidden
    }

    public var reference: References.Window
    public var gridID: Grid.ID
    public var frame: IntegerRectangle
    public var isHidden: Bool

    public var id: References.Window {
      reference
    }
  }

  public struct Cursor: Sendable, Equatable {
    public init(gridID: Grid.ID, position: IntegerPoint) {
      self.gridID = gridID
      self.position = position
    }

    public var gridID: Grid.ID
    public var position: IntegerPoint
  }

  public struct Snapshot: Sendable, Equatable {
    public init(font: Font? = nil, grids: IdentifiedArrayOf<State.Grid> = [], windows: IdentifiedArrayOf<State.Window> = [], cursor: State.Cursor? = nil) {
      self.font = font
      self.grids = grids
      self.windows = windows
      self.cursor = cursor
    }

    public var font: Font?
    public var grids: IdentifiedArrayOf<Grid>
    public var windows: IdentifiedArrayOf<Window>
    public var cursor: Cursor?

    public var outerGrid: Grid? {
      get {
        grids[id: .outer]
      }
      set {
        grids[id: .outer] = newValue
      }
    }
  }

  public var id: ID
  public var flushed: Snapshot?
  public var current: Snapshot
}

public extension State.Grid.ID {
  static var outer: Self {
    1
  }

  var isOuter: Bool {
    self == .outer
  }
}
