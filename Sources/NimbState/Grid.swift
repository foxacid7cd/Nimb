// SPDX-License-Identifier: MIT

import Algorithms
import NimbCore
import NimbNeovim

@PublicInit
public struct Grid: Sendable, Identifiable {
  public enum AssociatedWindow: Sendable {
    case plain(Window)
    case floating(FloatingWindow)
    case external(ExternalWindow)
  }

  public enum Update: Sendable {
    case resize(IntegerSize)
    case scroll(rectangle: IntegerRectangle, offset: IntegerSize)
    case clear
    case cursor(style: CursorStyle, position: IntegerPoint)
    case clearCursor
  }

  public enum UpdateResult: Sendable {
    case dirtyRectangles([IntegerRectangle])
    case needsDisplay

    /// The rectangles, merged. Coalescing lazily rather than in `formUnion`,
    /// since only one caller looks at the list and it accumulates all frame.
    public var coalescedRectangles: [IntegerRectangle] {
      switch self {
      case let .dirtyRectangles(dirtyRectangles):
        Self.coalesce(dirtyRectangles)
      case .needsDisplay:
        []
      }
    }

    public static func coalesced(_ dirtyRectangles: [IntegerRectangle]) -> Self {
      .dirtyRectangles(coalesce(dirtyRectangles))
    }

    private static func coalesce(_ dirtyRectangles: [IntegerRectangle]) -> [IntegerRectangle] {
      guard dirtyRectangles.count > 1 else {
        return dirtyRectangles
      }

      var coalescedRectangles: [IntegerRectangle] = []

      for dirtyRectangle in dirtyRectangles {
        guard dirtyRectangle.size.columnsCount > 0, dirtyRectangle.size.rowsCount > 0 else {
          continue
        }

        var mergedRectangle = dirtyRectangle
        var index = 0
        while index < coalescedRectangles.count {
          if shouldCoalesce(coalescedRectangles[index], with: mergedRectangle) {
            mergedRectangle = union(of: mergedRectangle, and: coalescedRectangles.remove(at: index))
          } else {
            index += 1
          }
        }

        coalescedRectangles.append(mergedRectangle)
      }

      return coalescedRectangles
    }

    private static func shouldCoalesce(
      _ lhs: IntegerRectangle,
      with rhs: IntegerRectangle,
    )
    -> Bool {
      lhs.intersects(with: rhs)
        || (lhs.rows == rhs.rows && rangesTouchOrOverlap(lhs.columns, rhs.columns))
        || (lhs.columns == rhs.columns && rangesTouchOrOverlap(lhs.rows, rhs.rows))
    }

    private static func union(
      of lhs: IntegerRectangle,
      and rhs: IntegerRectangle,
    )
    -> IntegerRectangle {
      let minColumn = min(lhs.minColumn, rhs.minColumn)
      let minRow = min(lhs.minRow, rhs.minRow)
      let maxColumn = max(lhs.maxColumn, rhs.maxColumn)
      let maxRow = max(lhs.maxRow, rhs.maxRow)

      return .init(
        origin: .init(column: minColumn, row: minRow),
        size: .init(
          columnsCount: maxColumn - minColumn,
          rowsCount: maxRow - minRow,
        ),
      )
    }

    private static func rangesTouchOrOverlap<T: Comparable>(
      _ lhs: Range<T>,
      _ rhs: Range<T>,
    )
    -> Bool {
      lhs.lowerBound <= rhs.upperBound && rhs.lowerBound <= lhs.upperBound
    }

    public mutating func formUnion(_ other: Self) {
      switch (self, other) {
      case (
        .dirtyRectangles(var accumulator),
        let .dirtyRectangles(dirtyRectangles),
      ):
        accumulator += dirtyRectangles
        self = .dirtyRectangles(accumulator)

      case (_, .needsDisplay):
        self = .needsDisplay

      default:
        break
      }
    }
  }

  @PublicInit
  public struct LineUpdatesResult: Sendable {
    public var row: Int
    public var rowCells: [Cell]
    public var rowLayout: RowLayout
    public var rowDrawRun: RowDrawRun
    public var dirtyRectangles: [IntegerRectangle]
    public var shouldUpdateCursorDrawRun: Bool
  }

  public static let OuterID = 1

  public var id: Int
  public var layout: GridLayout
  public var drawRuns: GridDrawRuns
  public var associatedWindow: AssociatedWindow? = nil
  public var isHidden: Bool

  public var size: IntegerSize {
    layout.size
  }

  public var windowSizeOrSize: IntegerSize {
    if case let .plain(window) = associatedWindow {
      window.size
    } else {
      size
    }
  }

  public var rowsCount: Int {
    size.rowsCount
  }

  public var columnsCount: Int {
    size.columnsCount
  }

  public var isFocusable: Bool {
    switch associatedWindow {
    case .plain:
      true
    case let .floating(floatingWindow):
      floatingWindow.isFocusable
    case .external:
      true
    default:
      true
    }
  }

  public init(
    id: Int,
    size: IntegerSize,
    font: Font,
    appearance: Appearance,
  ) {
    let layout = GridLayout(cells: .init(
      size: size,
      repeatingElement: Cell.whitespace,
    ))

    self.id = id
    self.layout = layout
    drawRuns = .init(
      layout: layout,
      font: font,
      appearance: appearance,
    )
    associatedWindow = nil
    isHidden = false
  }

  public mutating func apply(
    update: Update,
    font: Font,
    appearance: Appearance,
  )
    -> UpdateResult?
  {
    switch update {
    case let .resize(integerSize):
      let copyColumnsCount = min(layout.columnsCount, integerSize.columnsCount)
      let copyColumnsRange = 0 ..< copyColumnsCount
      let copyRowsCount = min(layout.rowsCount, integerSize.rowsCount)
      var cells = TwoDimensionalArray<Cell>(
        size: integerSize,
        repeatingElement: .whitespace,
      )
      for row in 0 ..< copyRowsCount {
        cells.replaceRow(
          row,
          columns: copyColumnsRange,
          with: layout.cells.rowSlice(row, columns: copyColumnsRange),
        )
      }
      layout = .init(cells: cells)

      // Reshaped in place, since rows keep their index across a resize and
      // index-aligned reuse can keep whatever survived. The font is unchanged.
      drawRuns.renderDrawRuns(for: layout, font: font, appearance: appearance)

      // Kept rather than cleared and restored; dropped only when the new size
      // no longer contains it.
      if
        let cursorDrawRun = drawRuns.cursorDrawRun,
        cursorDrawRun.origin.column >= integerSize.columnsCount
        || cursorDrawRun.origin.row >= integerSize.rowsCount
      {
        drawRuns.cursorDrawRun = nil
      }

      return .needsDisplay

    case let .scroll(rectangle, offset):
      if offset.columnsCount != 0 {
        logger.error("horizontal scroll not supported!!!")
      }

      var shouldUpdateCursorDrawRun = false

      let rowLayoutsCopy = layout.rowLayouts
      let rowDrawRunsCopy = drawRuns.rowDrawRuns

      let toRectangle = rectangle
        .applying(offset: -offset)
        .intersection(with: rectangle)

      let isFullWidth = rectangle.size.columnsCount == size.columnsCount
      // Only the narrower case reads the old cells; binding them otherwise
      // would make the first write copy the whole grid.
      let cellsCopy = isFullWidth ? nil : layout.cells

      // A full-width scroll only changes which row is where, so renumber them
      // and leave every cell put. Disturbed rows are destinations and sources.
      if isFullWidth {
        let lower = min(
          toRectangle.rows.lowerBound,
          toRectangle.rows.lowerBound + offset.rowsCount,
        )
        let upper = max(
          toRectangle.rows.upperBound,
          toRectangle.rows.upperBound + offset.rowsCount,
        )
        layout.cells.rotateRows(lower ..< upper, by: offset.rowsCount)
      }

      for toRow in toRectangle.rows {
        let fromRow = toRow + offset.rowsCount

        if isFullWidth {
          layout.rowLayouts[toRow] = rowLayoutsCopy[fromRow]
          drawRuns.rowDrawRuns[toRow] = rowDrawRunsCopy[fromRow]
        } else {
          layout.cells.replaceRow(
            toRow,
            columns: rectangle.columns,
            with: cellsCopy!.rowSlice(fromRow, columns: rectangle.columns),
          )
          layout.rowLayouts[toRow] = .init(rowCells: layout.cells.rowSlice(toRow))
          drawRuns.rowDrawRuns[toRow] = .init(
            row: toRow,
            layout: layout.rowLayouts[toRow],
            font: font,
            appearance: appearance,
            old: drawRuns.rowDrawRuns[toRow],
          )
        }

        if
          drawRuns.cursorDrawRun != nil,
          drawRuns.cursorDrawRun!.origin.row == toRow,
          rectangle.columns.contains(drawRuns.cursorDrawRun!.origin.column)
        {
          shouldUpdateCursorDrawRun = true
        }
      }

      if shouldUpdateCursorDrawRun {
        drawRuns.cursorDrawRun!.updateParent(
          with: layout,
          rowDrawRuns: drawRuns.rowDrawRuns,
        )
      }

      return .dirtyRectangles([toRectangle])

    case .clear:
      layout.cells = .init(size: layout.cells.size, repeatingElement: .whitespace)
      layout.rowLayouts = layout.cells.rowSlices
        .map(RowLayout.init(rowCells:))
      drawRuns.renderDrawRuns(for: layout, font: font, appearance: appearance)
      return .needsDisplay

    case let .cursor(style, position):
      let columnsCount =
        if position.row < layout.rowsCount, position.column < layout.columnsCount {
          layout.cells[position].isDoubleWidth ? 2 : 1
        } else {
          1
        }
      drawRuns.cursorDrawRun = .init(
        layout: layout,
        rowDrawRuns: drawRuns.rowDrawRuns,
        origin: position,
        columnsCount: columnsCount,
        style: style,
        font: font,
        appearance: appearance,
      )
      return .dirtyRectangles(
        [
          .init(
            origin: position,
            size: .init(columnsCount: columnsCount, rowsCount: 1),
          ),
        ],
      )

    case .clearCursor:
      guard let cursorDrawRun = drawRuns.cursorDrawRun else {
        return nil
      }
      drawRuns.cursorDrawRun = nil
      return .dirtyRectangles([cursorDrawRun.rectangle])
    }
  }

  public mutating func applyLineUpdate(
    originColumn: Int,
    cells: [Cell],
    row: Int,
    font: Font,
    appearance: Appearance,
  )
  -> IntegerRectangle {
    layout.cells.replaceRow(
      row,
      columns: originColumn ..< originColumn + cells.count,
      with: cells,
    )

    layout.rowLayouts[row].replaceCells(
      columns: originColumn ..< originColumn + cells.count,
      rowCells: layout.cells.rowSlice(row),
    )

    drawRuns.rowDrawRuns[row] = RowDrawRun(
      row: row,
      layout: layout.rowLayouts[row],
      font: font,
      appearance: appearance,
      old: drawRuns.rowDrawRuns[row],
    )

    return .init(
      origin: .init(column: originColumn, row: row),
      size: .init(columnsCount: cells.count, rowsCount: 1),
    )
  }

  public mutating func flushDrawRuns(font: Font, appearance: Appearance) {
    // Says outright that nothing may be reused, rather than disabling reuse
    // indirectly by emptying each row's cache.
    drawRuns.renderDrawRuns(for: layout, font: font, appearance: appearance, reusingOld: false)
    if let cursorDrawRun = drawRuns.cursorDrawRun {
      drawRuns.cursorDrawRun = .init(
        layout: layout,
        rowDrawRuns: drawRuns.rowDrawRuns,
        origin: cursorDrawRun.origin,
        columnsCount: cursorDrawRun.columnsCount,
        style: cursorDrawRun.style,
        font: font,
        appearance: appearance,
      )
    }
  }
}
