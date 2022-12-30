// SPDX-License-Identifier: MIT

import Algorithms
import ComposableArchitecture
import IdentifiedCollections
import Library
import Neovim
import SwiftUI
import Tagged

public extension Instance {
  struct State: Equatable, Identifiable {
    public init(
      id: State.ID,
      flushed: State.Snapshot? = nil,
      current: State.Snapshot = .init(),
      windowZIndexCounter: Int = 0,
      cursorPhase: Bool = true
    ) {
      self.id = id
      self.flushed = flushed
      self.current = current
      self.windowZIndexCounter = windowZIndexCounter
      self.cursorPhase = cursorPhase
    }

    // swiftformat:sort:begin

    public enum Anchor: String, Equatable {
      case northWest = "NW"
      case northEast = "NE"
      case southWest = "SW"
      case southEast = "SE"
    }

    public struct Appearance: Equatable {
      public init(
        font: Font,
        highlights: IdentifiedArrayOf<State.Highlight>,
        defaultForegroundColor: Color,
        defaultBackgroundColor: Color,
        defaultSpecialColor: Color
      ) {
        self.font = font
        self.highlights = highlights
        self.defaultForegroundColor = defaultForegroundColor
        self.defaultBackgroundColor = defaultBackgroundColor
        self.defaultSpecialColor = defaultSpecialColor
      }

      public var font: Font
      public var highlights: IdentifiedArrayOf<Highlight>
      public var defaultForegroundColor: Color
      public var defaultBackgroundColor: Color
      public var defaultSpecialColor: Color

      public var cellSize: CGSize {
        font.cellSize
      }

      public func foregroundColor(for highlightID: Highlight.ID) -> Color {
        highlights[id: highlightID]?.foregroundColor ?? defaultForegroundColor
      }

      public func backgroundColor(for highlightID: Highlight.ID) -> Color {
        highlights[id: highlightID]?.backgroundColor ?? defaultBackgroundColor
      }

      public func specialColor(for highlightID: Highlight.ID) -> Color {
        highlights[id: highlightID]?.specialColor ?? defaultSpecialColor
      }

      public func textAttributes(for highlightID: Highlight.ID) -> (isBold: Bool, isItalic: Bool) {
        guard let highlight = highlights[id: highlightID] else {
          return (false, false)
        }

        return (
          isBold: highlight.isBold,
          isItalic: highlight.isItalic
        )
      }
    }

    public struct Cell: Equatable {
      public init(text: String, highlightID: Highlight.ID) {
        self.text = text
        self.highlightID = highlightID
      }

      public static let `default` = Self(
        text: " ",
        highlightID: .default
      )

      public var text: String
      public var highlightID: Highlight.ID
    }

    public struct Color: Sendable, Hashable {
      public init(rgb: Int) {
        self.rgb = rgb
      }

      public var rgb: Int

      public var swiftUI: SwiftUI.Color {
        .init(
          .displayP3,
          red: Double((rgb >> 16) & 0xFF) / 255,
          green: Double((rgb >> 8) & 0xFF) / 255,
          blue: Double(rgb & 0xFF) / 255
        )
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

    public struct FloatingWindow: Equatable, Identifiable {
      public init(
        reference: References.Window,
        gridID: State.Grid.ID,
        anchor: Anchor,
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
      public var anchor: Anchor
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

    public struct Font: Sendable, Equatable {
      init(
        id: ID,
        cellWidth: Double,
        cellHeight: Double
      ) {
        self.id = id
        self.cellWidth = cellWidth
        self.cellHeight = cellHeight
      }

      public typealias ID = Tagged<Font, Int>

      public var id: ID
      public var cellWidth: Double
      public var cellHeight: Double

      public var cellSize: CGSize {
        .init(width: cellWidth, height: cellHeight)
      }
    }

    public struct Grid: Equatable, Identifiable {
      public init(
        id: ID,
        cells: TwoDimensionalArray<Cell>,
        rowLayouts: [RowLayout],
        windowID: References.Window?
      ) {
        self.id = id
        self.cells = cells
        self.rowLayouts = rowLayouts
        self.windowID = windowID
      }

      public typealias ID = Tagged<Grid, Int>

      public var id: ID
      public var cells: TwoDimensionalArray<Cell>
      public var rowLayouts: [RowLayout]
      public var windowID: References.Window?
    }

    public struct Highlight: Equatable, Identifiable {
      public init(
        id: ID,
        isBold: Bool = false,
        isItalic: Bool = false,
        foregroundColor: Color? = nil,
        backgroundColor: Color? = nil,
        specialColor: Color? = nil
      ) {
        self.id = id
        self.isBold = isBold
        self.isItalic = isItalic
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.specialColor = specialColor
      }

      public typealias ID = Tagged<Highlight, Int>

      public var id: ID
      public var isBold: Bool
      public var isItalic: Bool
      public var foregroundColor: Color?
      public var backgroundColor: Color?
      public var specialColor: Color?
    }

    public typealias ID = Tagged<State, String>

    public struct RowLayout: Equatable {
      public init(
        parts: [RowPart],
        cellIndices: [Range<Int>]
      ) {
        self.parts = parts
        self.cellIndices = cellIndices
      }

      public init(rowCells: ArraySlice<Cell>) {
        let chunks = rowCells.chunked {
          $0.highlightID == $1.highlightID && !$0.text.utf16.isEmpty
        }

        var parts = [RowPart]()
        var cellIndices = [Range<Int>]()

        var currentIndex = 0

        for cells in chunks {
          let lowerBound = currentIndex

          var text = ""

          for cell in cells {
            text.append(cell.text)

            let lowerBound = currentIndex
            currentIndex += cell.text.utf16.count
            let upperBound = currentIndex

            cellIndices.append(lowerBound..<upperBound)
          }

          let upperBound = currentIndex

          parts.append(
            .init(
              highlightID: cells.first!.highlightID,
              text: text,
              indices: lowerBound..<upperBound
            )
          )
        }

        self.init(
          parts: parts,
          cellIndices: cellIndices
        )
      }

      public var parts: [RowPart]
      public var cellIndices: [Range<Int>]
    }

    public struct RowPart: Equatable {
      public init(
        highlightID: Highlight.ID,
        text: String,
        indices: Range<Int>
      ) {
        self.highlightID = highlightID
        self.text = text
        self.indices = indices
      }

      public var highlightID: Highlight.ID
      public var text: String
      public var indices: Range<Int>
    }

    public struct Snapshot: Equatable {
      public init(
        defaultFont: Font? = nil,
        font: Font? = nil,
        title: String? = nil,
        highlights: IdentifiedArrayOf<Highlight> = [],
        grids: IdentifiedArrayOf<State.Grid> = [],
        windows: IdentifiedArrayOf<State.Window> = [],
        floatingWindows: IdentifiedArrayOf<FloatingWindow> = [],
        cursor: State.Cursor? = nil
      ) {
        self.defaultFont = defaultFont
        self.font = font
        self.title = title
        self.highlights = highlights
        self.grids = grids
        self.windows = windows
        self.cursor = cursor
        self.floatingWindows = floatingWindows
      }

      public var defaultFont: Font?
      public var font: Font?
      public var title: String?
      public var highlights: IdentifiedArrayOf<Highlight>
      public var grids: IdentifiedArrayOf<Grid>
      public var windows: IdentifiedArrayOf<Window>
      public var floatingWindows: IdentifiedArrayOf<FloatingWindow>
      public var cursor: Cursor?

      public var appearance: Appearance? {
        guard
          let font = font ?? defaultFont,
          let defaultHighlight = highlights[id: .default],
          let defaultForegroundColor = defaultHighlight.foregroundColor,
          let defaultBackgroundColor = defaultHighlight.backgroundColor,
          let defaultSpecialColor = defaultHighlight.specialColor
        else {
          return nil
        }

        return .init(
          font: font,
          highlights: highlights,
          defaultForegroundColor: defaultForegroundColor,
          defaultBackgroundColor: defaultBackgroundColor,
          defaultSpecialColor: defaultSpecialColor
        )
      }

      public var outerGrid: Grid? {
        grids[id: .outer]
      }
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

    // swiftformat:sort:end

    public var id: ID
    public var flushed: Snapshot?
    public var current: Snapshot
    public var windowZIndexCounter: Int
    public var cursorPhase: Bool

    public mutating func nextWindowZIndex() -> Int {
      windowZIndexCounter += 1
      return windowZIndexCounter
    }
  }
}

public extension Instance.State.Highlight.ID {
  static var `default`: Self {
    0
  }

  var isDefault: Bool {
    self == .default
  }
}

public extension Instance.State.Grid.ID {
  static var outer: Self {
    1
  }

  var isOuter: Bool {
    self == .outer
  }
}
