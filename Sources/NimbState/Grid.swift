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
        self = Self.coalesced(accumulator)

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
    size.rowsCount
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

      // Reshape in place rather than build a fresh GridDrawRuns.
      //
      // Constructing one starts from an empty rowDrawRuns, so its reuse never
      // had anything to reuse and every row was typeset again -- during a live
      // resize, once per throttled step. Rows keep their index across a
      // resize, which is exactly what index-aligned reuse needs: a row whose
      // content survived keeps its runs outright, and a row whose width
      // changed still keeps the parts that did not. Reuse compares content and
      // the bold/italic traits but not the font, and a resize does not change
      // the font, so it is safe here in a way it is not for SetFont.
      drawRuns.renderDrawRuns(for: layout, font: font, appearance: appearance)

      // Kept rather than cleared-and-restored, which is what building a fresh
      // GridDrawRuns forced. Same outcome: dropped only when the new size no
      // longer contains it.
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

      let cellsCopy = layout.cells
      let rowLayoutsCopy = layout.rowLayouts
      let rowDrawRunsCopy = drawRuns.rowDrawRuns

      let toRectangle = rectangle
        .applying(offset: -offset)
        .intersection(with: rectangle)

      let isFullWidth = rectangle.size.columnsCount == size.columnsCount

      // Moved as one block. Whole rows are contiguous in the cell buffer, and
      // a full-width scroll moves a contiguous run of them, so the row-by-row
      // form below was paying the slice and replaceSubrange plumbing once per
      // row for what is a single copy.
      if isFullWidth {
        layout.cells.copyRows(
          toRectangle.rows.lowerBound + offset.rowsCount
            ..< toRectangle.rows.upperBound + offset.rowsCount,
          from: cellsCopy,
          to: toRectangle.rows.lowerBound,
        )
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
            with: cellsCopy.rowSlice(fromRow, columns: rectangle.columns),
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

    layout.rowLayouts[row] = RowLayout(rowCells: layout.cells.rowSlice(row))
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
    // Emptying each row's cache used to be how this forced a reshape, and it
    // worked only indirectly: positional reuse could not start without a
    // dictionary hit, so clearing the dictionary disabled reuse as a whole.
    // Say so directly instead.
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
