// SPDX-License-Identifier: MIT

import Library
import Overture

@PublicInit
public struct GridLayout: Sendable {
  init(cells: TwoDimensionalArray<Cell>) {
    self.cells = cells
    rowLayouts = cells.rows
      .map(RowLayout.init(rowCells:))
  }

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
}

@PublicInit
public struct Cell: Sendable {
  public static let `default` = Self(
    text: " ",
    highlightID: .zero
  )

  public var text: String
  public var highlightID: Highlight.ID
}

@PublicInit
public struct RowLayout: Sendable {
  public init(rowCells: [Cell]) {
    let chunks = rowCells.chunked {
      !$0.text.isEmpty && $0.highlightID == $1.highlightID
    }

    var rowColumnsCount = 0
    var parts = [RowPart]()

    for cells in chunks {
      var partText = ""
      var partCells = [RowPart.Cell]()
      var partColumnsCount = 0

      for cellIndex in cells.indices {
        let nextCellIndex = cellIndex + 1

        let text = cells[cellIndex].text

        let textRangeStart = partText.endIndex
        partText.append(text)

        let columnsCount = if !text.isEmpty {
          if nextCellIndex < cells.endIndex, cells[nextCellIndex].text.isEmpty {
            2
          } else {
            1
          }
        } else {
          0
        }

        let columnsRangeStart = partColumnsCount
        partColumnsCount += columnsCount

        partCells.append(.init(
          textRange: textRangeStart ..< partText.endIndex,
          columnsRange: columnsRangeStart ..< partColumnsCount
        ))
      }

      let columnsRangeStart = rowColumnsCount
      rowColumnsCount += partColumnsCount

      parts.append(.init(
        highlightID: cells.first!.highlightID,
        text: partText,
        cells: partCells,
        columnsRange: columnsRangeStart ..< rowColumnsCount
      ))
    }

    self.init(
      parts: parts
    )
  }

  public var parts: [RowPart]
}

@PublicInit
public struct RowPart: Sendable, Hashable {
  @PublicInit
  public struct Cell: Sendable, Hashable {
    public var textRange: Range<String.Index>
    public var columnsRange: Range<Int>

    public var columnsCount: Int {
      columnsRange.count
    }
  }

  public var highlightID: Highlight.ID
  public var text: String
  public var cells: [Cell]
  public var columnsRange: Range<Int>

  public var columnsCount: Int {
    columnsRange.count
  }
}
