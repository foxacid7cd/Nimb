// SPDX-License-Identifier: MIT

import Algorithms
import Library

@PublicInit
public struct Grid: Sendable, Identifiable {
  public var id: Int
  public var cells: TwoDimensionalArray<Cell>
  public var rowLayouts: [RowLayout]
  public var associatedWindow: AssociatedWindow?
  public var isHidden: Bool

  public static let OuterID = 1

  @PublicInit
  public struct Cell: Sendable {
    public var text: String
    public var highlightID: Highlight.ID

    public static let `default` = Self(
      text: " ",
      highlightID: .zero
    )
  }

  public enum AssociatedWindow: Sendable {
    case plain(Window)
    case floating(FloatingWindow)
    case external(ExternalWindow)
  }

  @PublicInit
  public struct RowLayout: Sendable {
    public var parts: [RowPart]
    public var cellRanges: [(location: Int, length: Int)]

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
  }

  @PublicInit
  public struct RowPart: Sendable {
    public var highlightID: Highlight.ID
    public var text: String
    public var range: (location: Int, length: Int)
  }

  public var ordinal: Double {
    if id == 0 {
      0

    } else if let associatedWindow {
      switch associatedWindow {
      case let .plain(value):
        100 + Double(value.zIndex) / 100

      case let .floating(value):
        10000 + Double(value.zIndex) / 100

      case .external:
        1_000_000
      }

    } else {
      -1
    }
  }
}
