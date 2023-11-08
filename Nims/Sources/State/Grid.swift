// SPDX-License-Identifier: MIT

import Algorithms
import Library
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
      case (.dirtyRectangles(var accumulator), let .dirtyRectangles(dirtyRectangles)):
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
  public var isDestroyed: Bool

  public var size: IntegerSize {
    layout.size
  }

  public var rowsCount: Int {
    size.rowsCount
  }

  public var columnsCount: Int {
    size.rowsCount
  }

  public var zIndex: Double {
    if id == Grid.OuterID {
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

  public mutating func apply(update: Update, font: NimsFont, appearance: Appearance) -> UpdateResult? {
    switch update {
    case let .resize(integerSize):
      let copyColumnsCount = min(layout.columnsCount, integerSize.columnsCount)
      let copyColumnsRange = 0 ..< copyColumnsCount
      let copyRowsCount = min(layout.rowsCount, integerSize.rowsCount)
      var cells = TwoDimensionalArray<Cell>(size: integerSize, repeatingElement: .default)
      for row in 0 ..< copyRowsCount {
        cells.rows[row].replaceSubrange(
          copyColumnsRange,
          with: layout.cells.rows[row][copyColumnsRange]
        )
      }
      layout = .init(cells: cells)

      let cursorDrawRun = drawRuns.cursorDrawRun
      drawRuns = .init(layout: layout, font: font, appearance: appearance)

      if
        let cursorDrawRun,
        cursorDrawRun.position.column < integerSize.columnsCount,
        cursorDrawRun.position.row < integerSize.rowsCount
      {
        drawRuns.cursorDrawRun = cursorDrawRun
      }

      return .needsDisplay

    case let .scroll(rectangle, offset):
      if offset.columnsCount != 0 {
        assertionFailure("Horizontal scroll not supported")
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
          drawRuns.cursorDrawRun!.position.row == toRow,
          rectangle.columns.contains(drawRuns.cursorDrawRun!.position.column)
        {
          shouldUpdateCursorDrawRun = true
        }
      }

      if shouldUpdateCursorDrawRun {
        drawRuns.cursorDrawRun!.updateParent(with: layout, rowDrawRuns: drawRuns.rowDrawRuns)
      }

      return .dirtyRectangles([toRectangle])

    case .clear:
      layout.cells = .init(size: layout.cells.size, repeatingElement: .default)
      layout.rowLayouts = layout.cells.rows
        .map(RowLayout.init(rowCells:))
      drawRuns.renderDrawRuns(for: layout, font: font, appearance: appearance)
      return .needsDisplay

    case let .cursor(style, position):
      drawRuns.cursorDrawRun = .init(
        layout: layout,
        rowDrawRuns: drawRuns.rowDrawRuns,
        position: position,
        style: style,
        font: font,
        appearance: appearance
      )
      return .dirtyRectangles([.init(
        origin: position,
        size: .init(columnsCount: 1, rowsCount: 1)
      )])

    case .clearCursor:
      guard let cursorDrawRun = drawRuns.cursorDrawRun else {
        return nil
      }
      drawRuns.cursorDrawRun = nil
      return .dirtyRectangles([cursorDrawRun.rectangle])
    }
  }

  @Sendable
  public func applying(lineUpdates: [(originColumn: Int, cells: [Cell])], forRow row: Int, font: NimsFont, appearance: Appearance) -> LineUpdatesResult {
    var dirtyRectangles = [IntegerRectangle]()
    var shouldUpdateCursorDrawRun = false

    var rowCells = layout.cells.rows[row]
    for (originColumn, cells) in lineUpdates {
      rowCells.replaceSubrange(
        originColumn ..< originColumn + cells.count,
        with: cells
      )
      dirtyRectangles.append(.init(
        origin: .init(column: originColumn, row: row),
        size: .init(columnsCount: cells.count, rowsCount: 1)
      ))

      if 
        let cursorDrawRun = drawRuns.cursorDrawRun,
        cursorDrawRun.position.row == row,
        cursorDrawRun.position.column >= originColumn,
        cursorDrawRun.position.column < originColumn + cells.count
      {
        shouldUpdateCursorDrawRun = true
      }
    }
    let rowLayout = RowLayout(rowCells: rowCells)
    let rowDrawRun = RowDrawRun(
      row: row,
      layout: rowLayout,
      font: font,
      appearance: appearance,
      old: drawRuns.rowDrawRuns[row]
    )
    return .init(
      row: row,
      rowCells: rowCells,
      rowLayout: rowLayout,
      rowDrawRun: rowDrawRun,
      dirtyRectangles: dirtyRectangles,
      shouldUpdateCursorDrawRun: shouldUpdateCursorDrawRun
    )
  }

  public mutating func flushDrawRuns(font: NimsFont, appearance: Appearance) {
    for index in drawRuns.rowDrawRuns.indices {
      drawRuns.rowDrawRuns[index].drawRunsCache.removeAll(keepingCapacity: true)
    }
    drawRuns.renderDrawRuns(for: layout, font: font, appearance: appearance)
    if let cursorDrawRun = drawRuns.cursorDrawRun {
      drawRuns.cursorDrawRun = .init(
        layout: layout,
        rowDrawRuns: drawRuns.rowDrawRuns,
        position: cursorDrawRun.position,
        style: cursorDrawRun.style,
        font: font,
        appearance: appearance
      )
    }
  }
}
