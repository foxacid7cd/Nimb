// SPDX-License-Identifier: MIT

import Foundation
import Library
import Neovim
import SwiftUI
import Tagged

public enum Anchor: String, Equatable {
  case northWest = "NW"
  case northEast = "NE"
  case southWest = "SW"
  case southEast = "SE"
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
    gridID: Grid.ID,
    anchor: Anchor,
    anchorGridID: Grid.ID,
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

        cellIndices.append(lowerBound ..< upperBound)
      }

      let upperBound = currentIndex

      parts.append(
        .init(
          highlightID: cells.first!.highlightID,
          text: text,
          indices: lowerBound ..< upperBound
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

public extension Highlight.ID {
  static var `default`: Self {
    0
  }

  var isDefault: Bool {
    self == .default
  }
}

public extension Grid.ID {
  static var outer: Self {
    1
  }

  var isOuter: Bool {
    self == .outer
  }
}