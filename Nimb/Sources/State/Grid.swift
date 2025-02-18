// SPDX-License-Identifier: MIT

import Algorithms
import MyMacro
import Overture

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

    public mutating func formUnion(_ other: Self) {
      switch (self, other) {
      case (
        .dirtyRectangles(var accumulator),
        let .dirtyRectangles(dirtyRectangles)
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
  public var associatedWindow: AssociatedWindow?
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
    appearance: Appearance
  ) {
    let layout = GridLayout(cells: .init(
      size: size,
      repeatingElement: Cell.whitespace
    ))

    self.id = id
    self.layout = layout
    drawRuns = .init(
      layout: layout,
      font: font,
      appearance: appearance
    )
    associatedWindow = nil
    isHidden = false
  }

  public mutating func apply(
    update: Update,
    font: Font,
    appearance: Appearance
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
        repeatingElement: .whitespace
      )
      for row in 0 ..< copyRowsCount {
        cells.rows[row].replaceSubrange(
          copyColumnsRange,
          with: layout.cells.rows[row][copyColumnsRange]
        )
      }
      layout = .init(cells: cells)

      let cursorDrawRun = drawRuns.cursorDrawRun
      drawRuns = .init(
        layout: layout,
        font: font,
        appearance: appearance
      )

      if
        let cursorDrawRun,
        cursorDrawRun.origin.column < integerSize.columnsCount,
        cursorDrawRun.origin.row < integerSize.rowsCount
      {
        drawRuns.cursorDrawRun = cursorDrawRun
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

      for toRow in toRectangle.rows {
        let fromRow = toRow + offset.rowsCount

        if rectangle.size.columnsCount == size.columnsCount {
          layout.cells.rows[toRow] = cellsCopy.rows[fromRow]
          layout.rowLayouts[toRow] = rowLayoutsCopy[fromRow]
          drawRuns.rowDrawRuns[toRow] = rowDrawRunsCopy[fromRow]
        } else {
          layout.cells.rows[toRow].replaceSubrange(
            rectangle.columns,
            with: cellsCopy.rows[fromRow][rectangle.columns]
          )
          layout.rowLayouts[toRow] = .init(rowCells: layout.cells.rows[toRow])
          drawRuns.rowDrawRuns[toRow] = .init(
            row: toRow,
            layout: layout.rowLayouts[toRow],
            font: font,
            appearance: appearance,
            old: drawRuns.rowDrawRuns[toRow]
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
          rowDrawRuns: drawRuns.rowDrawRuns
        )
      }

      return .dirtyRectangles([toRectangle])

    case .clear:
      layout.cells = .init(size: layout.cells.size, repeatingElement: .whitespace)
      layout.rowLayouts = layout.cells.rows
        .map(RowLayout.init(rowCells:))
      drawRuns.renderDrawRuns(for: layout, font: font, appearance: appearance)
      return .needsDisplay

    case let .cursor(style, position):
      let columnsCount =
        if position.row < layout.rowsCount, position.column < layout.columnsCount {
          layout.cells.rows[position.row][position.column].isDoubleWidth ? 2 : 1
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
        appearance: appearance
      )
      return .dirtyRectangles(
        [
          .init(
            origin: position,
            size: .init(columnsCount: columnsCount, rowsCount: 1)
          ),
        ]
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
    appearance: Appearance
  )
  -> IntegerRectangle {
    layout.cells.rows[row].replaceSubrange(
      originColumn ..< originColumn + cells.count,
      with: cells
    )

    layout.rowLayouts[row] = RowLayout(rowCells: layout.cells.rows[row])
    drawRuns.rowDrawRuns[row] = RowDrawRun(
      row: row,
      layout: layout.rowLayouts[row],
      font: font,
      appearance: appearance,
      old: drawRuns.rowDrawRuns[row]
    )

    return .init(
      origin: .init(column: originColumn, row: row),
      size: .init(columnsCount: cells.count, rowsCount: 1)
    )
  }

  public mutating func flushDrawRuns(font: Font, appearance: Appearance) {
    for index in drawRuns.rowDrawRuns.indices {
      drawRuns.rowDrawRuns[index].drawRunsCache.removeAll(keepingCapacity: true)
    }
    drawRuns.renderDrawRuns(for: layout, font: font, appearance: appearance)
    if let cursorDrawRun = drawRuns.cursorDrawRun {
      drawRuns.cursorDrawRun = .init(
        layout: layout,
        rowDrawRuns: drawRuns.rowDrawRuns,
        origin: cursorDrawRun.origin,
        columnsCount: cursorDrawRun.columnsCount,
        style: cursorDrawRun.style,
        font: font,
        appearance: appearance
      )
    }
  }
}
