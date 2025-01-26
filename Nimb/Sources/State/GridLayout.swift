// SPDX-License-Identifier: MIT

import AppKit
import Overture

@PublicInit
public struct GridLayout: Sendable {
  public var cells: TwoDimensionalArray<Cell>
  public var rowLayouts: [RowLayout]

  public var columnsCount: Int {
    cells.columnsCount
  }

  public var rowsCount: Int {
    cells.rowsCount
  }

  public var size: IntegerSize {
    cells.size
  }

  init(cells: TwoDimensionalArray<Cell>) {
    self.cells = cells
    rowLayouts = cells.rows
      .map(RowLayout.init(rowCells:))
  }
}

@PublicInit
public struct Cell: Sendable, Hashable {
  public static let `default` = Self(
    character: " ",
    isDoubleWidth: false,
    highlightID: .zero
  )

  public var character: Character
  public var isDoubleWidth: Bool
  public var highlightID: Highlight.ID
}

@PublicInit
public struct RowLayout: Sendable {
  public var parts: [RowPart]

  public init(rowCells: [Cell]) {
    var parts = [RowPart]()
    for (index, rowCell) in rowCells.enumerated() {
      let rowPartCell = RowPartCell(
        character: rowCell.character,
        isDoubleWidth: rowCell.isDoubleWidth
      )
      let previousCell = index > 0 ? rowCells[index - 1] : nil
      let previousOfPreviousCell = index > 1 ? rowCells[index - 2] : nil

      if
        parts
          .isEmpty || (
            previousCell?.highlightID != rowCell.highlightID && !parts[parts.count - 1].cells.isEmpty
          ) || rowCell.isDoubleWidth || previousOfPreviousCell?.isDoubleWidth == true
      {
        parts
          .append(
            .init(highlightID: rowCell.highlightID, cells: [], originColumn: index)
          )
      }
      parts[parts.count - 1].cells.append(rowPartCell)
    }

    self.init(
      parts: parts
    )
  }
}

@PublicInit
public struct RowPartCell: Sendable, Hashable {
  public var character: Character
  public var isDoubleWidth: Bool
}

@PublicInit
public struct RowPart: Sendable, Hashable {
  public var highlightID: Highlight.ID
  public var cells: [RowPartCell]
  public var originColumn: Int

  public var columnsCount: Int {
    cells.count
  }

  public var columnsRange: Range<Int> {
    originColumn ..< originColumn + columnsCount
  }
}
