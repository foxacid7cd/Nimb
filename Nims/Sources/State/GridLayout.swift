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
    let chunks = rowCells
      .chunked { $0.highlightID == $1.highlightID }

    var parts = [RowPart]()
    var cellRanges = [(location: Int, length: Int)]()

    var charactersCount = 0

    for cells in chunks {
      let partLocation = charactersCount

      var text = ""
      var partLength = 0

      for cellIndex in cells.indices {
        let nextCellIndex = cellIndex + 1

        let cell = cells[cellIndex]
        text.append(cell.text)

        let cellLength = if !cell.text.isEmpty {
          if nextCellIndex < cells.endIndex, cells[nextCellIndex].text.isEmpty {
            2
          } else {
            1
          }
        } else {
          0
        }

        cellRanges.append((partLocation + partLength, cellLength))

        partLength += cellLength
      }

      parts.append(
        .init(
          highlightID: cells.first!.highlightID,
          text: text,
          range: (charactersCount, partLength)
        )
      )

      charactersCount += partLength
    }

    self.init(
      parts: parts,
      cellRanges: cellRanges
    )
  }

  public var parts: [RowPart]
  public var cellRanges: [(location: Int, length: Int)]
}

@PublicInit
public struct RowPart: Sendable {
  public var highlightID: Highlight.ID
  public var text: String
  public var range: (location: Int, length: Int)
}
