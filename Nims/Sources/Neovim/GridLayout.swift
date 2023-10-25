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

//  public mutating func apply(textUpdate: Grid.TextUpdate) {
//    switch textUpdate {
//    case let .resize(integerSize):
//      cells = TwoDimensionalArray<Cell>(size: integerSize) { point in
//        if point.row < cells.rowsCount, point.column < cells.columnsCount {
//          return cells[point]
//        }
//        return .default
//      }
//      rowLayouts = cells.rows
//        .map(RowLayout.init(rowCells:))
//
//    case let .line(origin, cells):
//      update(&self.cells.rows[origin.row]) { row in
//        row.replaceSubrange(origin.column ..< origin.column + cells.count, with: cells)
//      }
//      rowLayouts[origin.row] = .init(rowCells: self.cells.rows[origin.row])
//
//    case let .scroll(rectangle, offset):
//      if offset.columnsCount != 0 {
//        assertionFailure("Horizontal scroll not supported")
//      }
//
//      let cellsCopy = cells
//      let rowLayoutsCopy = rowLayouts
//
//      let fromRows = rectangle.minRow ..< rectangle.maxRow
//      for fromRow in fromRows {
//        let toRow = fromRow - offset.rowsCount
//
//        guard
//          toRow >= rectangle.minRow,
//          toRow < min(rowsCount, rectangle.maxRow)
//        else {
//          continue
//        }
//
//        cells.rows[toRow] = cellsCopy.rows[fromRow]
//        rowLayouts[toRow] = rowLayoutsCopy[fromRow]
//      }
//
//    case .clear:
//      cells = .init(size: cells.size, repeatingElement: .default)
//      rowLayouts = cells.rows
//        .map(RowLayout.init(rowCells:))
//    }
//  }
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
