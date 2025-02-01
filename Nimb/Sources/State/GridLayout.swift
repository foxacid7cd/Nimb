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
  public static let whitespace = Self(
    character: " ",
    isDoubleWidth: false,
    highlightID: .zero
  )

  public var character: Character?
  public var isDoubleWidth: Bool
  public var highlightID: Highlight.ID
}

@PublicInit
public struct RowLayout: Sendable {
  public var parts: [RowPart]

  public init(rowCells: [Cell]) {
    var accumulator = RowPartsAccumulator()
    for cell in rowCells {
      accumulator.append(cell)
    }
    self.init(parts: accumulator.rowParts)

    struct RowPartsAccumulator {
      private enum InternalPartContent {
        case whitespaceCharacters(count: Int)
        case doubleWidthCharacter(Character, isWithSecondFillerCharacter: Bool)
        case singleWidthCharacters([Character])
      }

      private struct InternalPart {
        var content: InternalPartContent
        var highlightID: Highlight.ID
        var originColumn: Int
      }

      private var cellsCount = 0
      private var internalParts: [InternalPart] = []

      mutating func append(_ cell: Cell) {
        defer { cellsCount += 1 }

        enum CellCharacterType {
          case whitespace
          case regular(Character, isDoubleWidth: Bool)
          case missing
        }
        let cellCharacterType: CellCharacterType =
          if let character = cell.character {
            if character.isWhitespace {
              .whitespace
            } else {
              .regular(character, isDoubleWidth: cell.isDoubleWidth)
            }
          } else {
            .missing
          }

        if let lastPart = internalParts.last {
          if lastPart.highlightID == cell.highlightID {
            switch (lastPart.content, cellCharacterType) {
            case let (.whitespaceCharacters(count), .whitespace):
              internalParts[internalParts.count - 1].content = .whitespaceCharacters(
                count: count + 1
              )
              return

            case (.doubleWidthCharacter(let character, false), .missing):
              internalParts[internalParts.count - 1].content = .doubleWidthCharacter(
                character,
                isWithSecondFillerCharacter: true
              )
              return

            case (.singleWidthCharacters(var characters), .regular(let character, false)):
              characters.append(character)
              internalParts[internalParts.count - 1].content = .singleWidthCharacters(
                characters
              )
              return

            default:
              break
            }
          }
        }

        let content: InternalPartContent =
          switch cellCharacterType {
          case .whitespace:
            .whitespaceCharacters(count: 1)

          case let .regular(character, isDoubleWidth):
            if isDoubleWidth {
              .doubleWidthCharacter(character, isWithSecondFillerCharacter: false)
            } else {
              .singleWidthCharacters([character])
            }

          case .missing:
            .whitespaceCharacters(count: 1)
          }
        internalParts.append(
          .init(content: content, highlightID: cell.highlightID, originColumn: cellsCount)
        )
      }

      var rowParts: [RowPart] {
        internalParts
          .map { internalPart in
            let content: RowPartContent =
              switch internalPart.content {
              case let .whitespaceCharacters(count):
                .whitespace(columnsCount: count)

              case let .doubleWidthCharacter(character, isWithSecondFillerCharacter):
                if isWithSecondFillerCharacter {
                  .cells([
                    .init(character: character, isDoubleWidth: true),
                    .init(character: " ", isDoubleWidth: false),
                  ])
                } else {
                  .cells([
                    .init(character: character, isDoubleWidth: true),
                  ])
                }

              case let .singleWidthCharacters(characters):
                .cells(characters.map { .init(character: $0, isDoubleWidth: false) })
              }
            return RowPart(
              content: content,
              highlightID: internalPart.highlightID,
              originColumn: internalPart.originColumn
            )
          }
      }
    }
  }
}

@PublicInit
public struct RowPartCell: Sendable, Hashable {
  public var character: Character
  public var isDoubleWidth: Bool
}

public enum RowPartContent: Sendable, Hashable {
  case cells([RowPartCell])
  case whitespace(columnsCount: Int)

  public var columnsCount: Int {
    switch self {
    case let .cells(cells):
      cells.count
    case let .whitespace(columnsCount):
      columnsCount
    }
  }

  public var isWhitespace: Bool {
    switch self {
    case .whitespace:
      true
    default:
      false
    }
  }
}

@PublicInit
public struct RowPart: Sendable, Hashable {
  public var content: RowPartContent
  public var highlightID: Highlight.ID
  public var originColumn: Int

  public var columnsCount: Int {
    content.columnsCount
  }

  public var columnsRange: Range<Int> {
    originColumn ..< originColumn + columnsCount
  }
}
