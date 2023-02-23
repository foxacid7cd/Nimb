// SPDX-License-Identifier: MIT

import Foundation
import IdentifiedCollections
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

public enum CursorShape: String {
  case block
  case horizontal
  case vertical
}

public struct CursorStyle: Equatable {
  public init(
    name: String?,
    shortName: String?,
    mouseShape: Int?,
    blinkOn: Int?,
    blinkOff: Int?,
    blinkWait: Int?,
    cellPercentage: Int?,
    cursorShape: CursorShape?,
    idLm: Int?,
    attrID: Highlight.ID?,
    attrIDLm: Int?
  ) {
    self.name = name
    self.shortName = shortName
    self.mouseShape = mouseShape
    self.blinkOn = blinkOn
    self.blinkOff = blinkOff
    self.blinkWait = blinkWait
    self.cellPercentage = cellPercentage
    self.cursorShape = cursorShape
    self.idLm = idLm
    self.attrID = attrID
    self.attrIDLm = attrIDLm
  }

  public var name: String?
  public var shortName: String?
  public var mouseShape: Int?
  public var blinkOn: Int?
  public var blinkOff: Int?
  public var blinkWait: Int?
  public var cellPercentage: Int?
  public var cursorShape: CursorShape?
  public var idLm: Int?
  public var attrID: Highlight.ID?
  public var attrIDLm: Int?
}

public struct ModeInfo: Equatable {
  public init(enabled: Bool, cursorStyles: [CursorStyle]) {
    self.enabled = enabled
    self.cursorStyles = cursorStyles
  }

  public var enabled: Bool
  public var cursorStyles: [CursorStyle]
}

public struct Mode: Equatable {
  public init(name: String, cursorStyleIndex: Int) {
    self.name = name
    self.cursorStyleIndex = cursorStyleIndex
  }

  public var name: String
  public var cursorStyleIndex: Int
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

public struct Grid: Equatable, Identifiable {
  public init(
    id: Grid.ID,
    cells: TwoDimensionalArray<Cell>,
    rowLayouts: [RowLayout],
    windowID: References.Window? = nil,
    updates: [IntegerRectangle],
    updateFlag: Bool
  ) {
    self.id = id
    self.cells = cells
    self.rowLayouts = rowLayouts
    self.windowID = windowID
    self.updates = updates
    self.updateFlag = updateFlag
  }

  public typealias ID = Tagged<Grid, Int>

  public var id: ID
  public var cells: TwoDimensionalArray<Cell>
  public var rowLayouts: [RowLayout]
  public var windowID: References.Window?
  public var updates: [IntegerRectangle]
  public var updateFlag: Bool
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

public struct Tab: Equatable, Identifiable {
  public var id: References.Tabpage
  public var name: String
}

public struct Tabline: Equatable {
  public var currentTabID: Tab.ID
  public var tabs: IdentifiedArrayOf<Tab>
}

public struct CmdlineContentPart: Equatable {
  public var highlightID: Highlight.ID
  public var text: String
}

public struct Cmdline: Equatable, Identifiable {
  public var contentParts: [CmdlineContentPart]
  public var cursorPosition: Int
  public var firstCharacter: String
  public var prompt: String
  public var indent: Int
  public var level: Int
  public var specialCharacter: String
  public var shiftAfterSpecialCharacter: Bool
  public var blockLines: [[CmdlineContentPart]]

  public var id: Int {
    level
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
