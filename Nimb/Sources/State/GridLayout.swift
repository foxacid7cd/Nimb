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
    var chunks = [[Cell]]()
    for (index, rowCell) in rowCells.enumerated() {
      let previousCell = index > 0 ? rowCells[index - 1] : nil

      if
        chunks
          .isEmpty || (
            previousCell?.highlightID != rowCell.highlightID && !chunks[chunks.count - 1].isEmpty
          )
      {
        chunks.append([])
      }
      chunks[chunks.count - 1].append(rowCell)

      let isPreviousCellDoubleWidth = index > 0 && rowCells[index - 1].isDoubleWidth
      if isPreviousCellDoubleWidth, index != rowCells.count - 1 {
        chunks.append([])
      }
    }

    var rowColumnsCount = 0
    var parts = [RowPart]()

    for cells in chunks {
      parts.append(.init(highlightID: cells.first!.highlightID, cells: cells, columnsRange: rowColumnsCount ..< rowColumnsCount + cells.count))
      rowColumnsCount += cells.count
    }

//    let attributedString = NSMutableAttributedString()
//
//    var string = ""
//    var currentHighlightID: Highlight.ID?
//    func appendAttributedString() {
//      attributedString
//        .append(
//          .init(
//            attributedString: .init(
//              string: string,
//              attributes: [.highlightID: currentHighlightID!]
//            )
//          )
//        )
//      string = ""
//      currentHighlightID = nil
//    }
//    for cell in rowCells {
//      if currentHighlightID == nil {
//        currentHighlightID = cell.highlightID
//      }
//      if currentHighlightID != cell.highlightID {
//        appendAttributedString()
//      }
//      string.append(cell.text)
//    }
//    appendAttributedString()

    self.init(
      parts: parts
    )
  }
}

@PublicInit
public struct RowPart: Sendable, Hashable {
  public var highlightID: Highlight.ID
  public var cells: [Cell]
  public var columnsRange: Range<Int>

  public var columnsCount: Int {
    columnsRange.count
  }
}
