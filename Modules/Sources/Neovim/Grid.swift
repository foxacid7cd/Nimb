// SPDX-License-Identifier: MIT

import Algorithms
import Library
import Tagged

public struct Grid: Sendable, Identifiable {
  public var id: ID
  public var cells: TwoDimensionalArray<Cell>
  public var rowLayouts: [RowLayout]
  public var associatedWindow: AssociatedWindow?
  public var isHidden: Bool

  public typealias ID = Tagged<Grid, Int>

  public struct Cell: Sendable {
    public init(text: String, highlightID: Highlight.ID) {
      self.text = text
      self.highlightID = highlightID
    }

    public static let `default` = Self(
      text: " ",
      highlightID: .zero
    )

    public var text: String
    public var highlightID: Highlight.ID
  }

  public enum AssociatedWindow: Sendable {
    case plain(Window)
    case floating(FloatingWindow)
    case external(ExternalWindow)
  }

  public struct RowLayout: Sendable {
    public init(
      parts: [RowPart],
      cellIndices: [Range<Int>]
    ) {
      self.parts = parts
      self.cellIndices = cellIndices
    }

    public init(rowCells: [Cell]) {
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

  public struct RowPart: Sendable {
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

  public var ordinal: Double {
    if id == .outer {
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

public extension Grid.ID {
  static var outer: Self {
    1
  }

  var isOuter: Bool {
    self == .outer
  }
}
