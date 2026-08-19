// SPDX-License-Identifier: MIT

import AppKit
import NimbCore

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
    rowLayouts = cells.rowSlices
      .map(RowLayout.init(rowCells:))
  }
}

@PublicInit
public struct Cell: Sendable, Hashable {
  public static let whitespace = Self(
    character: " ",
    isDoubleWidth: false,
    highlightID: .zero,
  )

  public var character: Character? = nil
  public var isDoubleWidth: Bool
  public var highlightID: Highlight.ID
}

@PublicInit
public struct RowLayout: Sendable {
  public var parts: [RowPart]

  public init(rowCells: ArraySlice<Cell>) {
    var accumulator = RowPartsAccumulator(startColumn: 0)
    for cell in rowCells {
      accumulator.append(cell)
    }
    self.init(parts: accumulator.rowParts)
  }

  /// Re-splits only the parts `columns` touches, given the row it now holds.
  ///
  /// A grid_line usually rewrites part of a row — every keystroke does — but
  /// the row was being split end to end regardless, which sampling put at 47%
  /// of the reducer while typing.
  ///
  /// `rowCells` is the whole row after the update, not just the changed span:
  /// the rebuilt window reaches past the edit on both sides.
  public mutating func replaceCells(
    columns: Range<Int>,
    rowCells: ArraySlice<Cell>,
  ) {
    guard
      !columns.isEmpty,
      let firstChanged = partIndex(containing: columns.lowerBound),
      let lastChanged = partIndex(containing: columns.upperBound - 1)
    else {
      self = .init(rowCells: rowCells)
      return
    }

    // One part either side of the edit, because the edited cells can merge
    // into the run next to them — and if they consume that run entirely, into
    // the one after it. Rebuilding from the neighbour's own start settles
    // both at once: its leading cells did not change, so whether it merges
    // with the part beyond it cannot have changed either, and the cascade
    // stops there.
    let firstIndex = max(firstChanged - 1, 0)
    let lastIndex = min(lastChanged + 1, parts.count - 1)

    let rebuilt = parts[firstIndex].originColumn
      ..< parts[lastIndex].columnsRange.upperBound

    // Once the window covers the row there is nothing left to reuse, and the
    // straight rebuild is cheaper than splicing.
    guard rebuilt.count < rowCells.count else {
      self = .init(rowCells: rowCells)
      return
    }

    var accumulator = RowPartsAccumulator(startColumn: rebuilt.lowerBound)
    for column in rebuilt {
      accumulator.append(rowCells[rowCells.startIndex + column])
    }

    // The window spans the same columns as the parts it replaces, so every
    // part after it keeps its origin.
    parts.replaceSubrange(firstIndex ... lastIndex, with: accumulator.rowParts)
  }

  /// The part covering `column`. Parts are contiguous and ordered, so this is
  /// a binary search.
  private func partIndex(containing column: Int) -> Int? {
    var low = 0
    var high = parts.count - 1
    while low <= high {
      let middle = (low + high) / 2
      let range = parts[middle].columnsRange
      if column < range.lowerBound {
        high = middle - 1
      } else if column >= range.upperBound {
        low = middle + 1
      } else {
        return middle
      }
    }
    return nil
  }
}

private struct RowPartsAccumulator {
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

  /// The column the first appended cell sits at, so a window rebuilt from
  /// the middle of a row still reports absolute origins.
  private let startColumn: Int
  private var cellsCount = 0
  private var internalParts: [InternalPart] = []

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
          originColumn: internalPart.originColumn,
        )
      }
  }

  init(startColumn: Int) {
    self.startColumn = startColumn
  }

  mutating func append(_ cell: Cell) {
    defer { cellsCount += 1 }

    enum CellCharacterType {
      case whitespace
      case regular(Character, isDoubleWidth: Bool)
      case missing
    }
    let cellCharacterType: CellCharacterType =
      if let character = cell.character {
        // Space is checked first because almost every whitespace cell in a
        // terminal grid is one. Character.isWhitespace resolves a Unicode
        // binary property, which sampling put at 4.4% of the reducer while
        // scrolling -- paid once per cell of every row rebuilt.
        if character == " " || character.isWhitespace {
          .whitespace
        } else {
          .regular(character, isDoubleWidth: cell.isDoubleWidth)
        }
      } else {
        .missing
      }

    // Deliberately indexed rather than going through internalParts.last:
    // that binds a copy, which leaves the character array in
    // singleWidthCharacters referenced twice, so appending to it triggers
    // copy-on-write of the whole run. For a row of plain text that is a
    // copy per character, quadratic in the run length.
    if !internalParts.isEmpty {
      let lastIndex = internalParts.index(before: internalParts.endIndex)
      if internalParts[lastIndex].highlightID == cell.highlightID {
        switch cellCharacterType {
        case .whitespace:
          if case let .whitespaceCharacters(count) = internalParts[lastIndex].content {
            internalParts[lastIndex].content = .whitespaceCharacters(count: count + 1)
            return
          }

        case .missing:
          if
            case let .doubleWidthCharacter(character, false) = internalParts[lastIndex]
              .content
          {
            internalParts[lastIndex].content = .doubleWidthCharacter(
              character,
              isWithSecondFillerCharacter: true,
            )
            return
          }

        case let .regular(character, false):
          if case var .singleWidthCharacters(characters) = internalParts[lastIndex].content {
            // Drop the enum's reference before appending so the array is
            // uniquely referenced and grows in place.
            internalParts[lastIndex].content = .whitespaceCharacters(count: 0)
            characters.append(character)
            internalParts[lastIndex].content = .singleWidthCharacters(characters)
            return
          }

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
      .init(
        content: content,
        highlightID: cell.highlightID,
        originColumn: startColumn + cellsCount,
      ),
    )
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
