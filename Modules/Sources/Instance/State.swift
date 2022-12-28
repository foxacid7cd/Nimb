// SPDX-License-Identifier: MIT

import Algorithms
import ComposableArchitecture
import IdentifiedCollections
import Library
import Neovim
import Tagged

public struct State: Equatable, Identifiable {
  public init(id: State.ID, flushed: State.Snapshot? = nil, current: State.Snapshot = .init(), windowZIndexCounter: Int = 0) {
    self.id = id
    self.flushed = flushed
    self.current = current
    self.windowZIndexCounter = windowZIndexCounter
  }

  public typealias ID = Tagged<State, String>

  public struct Grid: Equatable, Identifiable {
    public init(id: ID, cells: TwoDimensionalArray<Cell>, rowHighlightChunks: [[HighlightChunk]]) {
      self.id = id
      self.cells = cells
      self.rowHighlightChunks = rowHighlightChunks
    }

    public typealias ID = Tagged<Grid, Int>

    public var id: ID
    public var cells: TwoDimensionalArray<Cell>
    public var rowHighlightChunks: [[HighlightChunk]]
  }

  public struct HighlightChunk: Equatable {
    public init(highlightID: Highlight.ID, text: String, originColumn: Int, columnsCount: Int) {
      self.highlightID = highlightID
      self.text = text
      self.originColumn = originColumn
      self.columnsCount = columnsCount
    }

    public var highlightID: Highlight.ID
    public var text: String
    public var originColumn: Int
    public var columnsCount: Int
  }

  public struct Window: Equatable, Identifiable {
    public init(reference: References.Window, gridID: Grid.ID, frame: IntegerRectangle, zIndex: Int, isHidden: Bool) {
      self.reference = reference
      self.gridID = gridID
      self.frame = frame
      self.zIndex = zIndex
      self.isHidden = isHidden
    }

    public var reference: References.Window
    public var gridID: Grid.ID
    public var frame: IntegerRectangle
    public var zIndex: Int
    public var isHidden: Bool

    public var id: References.Window {
      reference
    }
  }

  public struct FloatingWindow: Equatable, Identifiable {
    public init(
      reference: References.Window,
      gridID: State.Grid.ID,
      anchor: String,
      anchorGridID: State.Grid.ID,
      anchorRow: Double,
      anchorColumn: Double,
      isFocusable: Bool,
      zIndex: Int,
      isHidden: Bool
    ) {
      self.reference = reference
      self.gridID = gridID
      self.anchor = anchor
      self.anchorGridID = anchorGridID
      self.anchorRow = anchorRow
      self.anchorColumn = anchorColumn
      self.isFocusable = isFocusable
      self.zIndex = zIndex
      self.isHidden = isHidden
    }

    public var reference: References.Window
    public var gridID: Grid.ID
    public var anchor: String
    public var anchorGridID: Grid.ID
    public var anchorRow: Double
    public var anchorColumn: Double
    public var isFocusable: Bool
    public var zIndex: Int
    public var isHidden: Bool

    public var id: References.Window {
      reference
    }
  }

  public struct Cursor: Equatable {
    public init(gridID: Grid.ID, position: IntegerPoint) {
      self.gridID = gridID
      self.position = position
    }

    public var gridID: Grid.ID
    public var position: IntegerPoint
  }

  public struct Snapshot: Equatable {
    public init(
      font: Font? = nil,
      grids: IdentifiedArrayOf<State.Grid> = [],
      windows: IdentifiedArrayOf<State.Window> = [],
      floatingWindows: IdentifiedArrayOf<FloatingWindow> = [],
      cursor: State.Cursor? = nil
    ) {
      self.font = font
      self.grids = grids
      self.windows = windows
      self.cursor = cursor
      self.floatingWindows = floatingWindows
    }

    public var font: Font?
    public var grids: IdentifiedArrayOf<Grid>
    public var windows: IdentifiedArrayOf<Window>
    public var floatingWindows: IdentifiedArrayOf<FloatingWindow>
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
  public var windowZIndexCounter: Int

  public mutating func nextWindowZIndex() -> Int {
    windowZIndexCounter += 1
    return windowZIndexCounter
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

public extension TwoDimensionalArray<Cell>.RowsView.Element {
  func makeHighlightChunks() -> [State.HighlightChunk] {
    chunked(on: \.highlightID)
      .map { highlightID, cells in
        let text = cells
          .map(\.text)
          .joined()

        return .init(
          highlightID: highlightID,
          text: text,
          originColumn: cells.startIndex - startIndex,
          columnsCount: cells.endIndex - cells.startIndex
        )
      }
  }
}
