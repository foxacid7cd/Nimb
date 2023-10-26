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

  public enum TextUpdate: Sendable {
    case resize(IntegerSize)
    case line(origin: IntegerPoint, cells: [Cell])
    case scroll(rectangle: IntegerRectangle, offset: IntegerSize)
    case clear
    case cursor(style: CursorStyle, position: IntegerPoint)
    case clearCursor
  }

  public enum TextUpdateApplyResult {
    case dirtyRectangle(IntegerRectangle)
    case needsDisplay
  }

  public struct LineUpdateResult: Sendable {
    public var row: Int
    public var rowCells: [Cell]
    public var rowLayout: RowLayout
    public var rowDrawRun: RowDrawRun
    public var dirtyRectangle: IntegerRectangle
    public var shouldUpdateCursorDrawRun: Bool
  }

  public static let OuterID = 1

  public var id: Int
  public var layout: GridLayout
  public var drawRunsProvider: DrawRunsCachingProvider
  public var drawRuns: GridDrawRuns
  public var associatedWindow: AssociatedWindow?
  public var isHidden: Bool

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

  @NeovimActor
  public mutating func apply(textUpdate: TextUpdate, font: NimsFont, appearance: Appearance) -> TextUpdateApplyResult? {
    switch textUpdate {
    case let .resize(integerSize):
      layout.cells = TwoDimensionalArray<Cell>(size: integerSize) { point in
        if point.row < layout.cells.rowsCount, point.column < layout.cells.columnsCount {
          return layout.cells[point]
        }
        return .default
      }
      layout.rowLayouts = layout.cells.rows
        .map(RowLayout.init(rowCells:))

      drawRuns.renderDrawRuns(for: layout, font: font, appearance: appearance, drawRunsProvider: drawRunsProvider)

      if
        let cursorDrawRun = drawRuns.cursorDrawRun,
        cursorDrawRun.position.column >= integerSize.columnsCount || cursorDrawRun.position.row >= integerSize.rowsCount
      {
        drawRuns.cursorDrawRun = nil
      }

      return .needsDisplay

    case let .line(origin, cells):
      update(&layout.cells.rows[origin.row]) { row in
        row.replaceSubrange(origin.column ..< origin.column + cells.count, with: cells)
      }
      layout.rowLayouts[origin.row] = .init(rowCells: layout.cells.rows[origin.row])

      drawRuns.rowDrawRuns[origin.row] = .init(
        row: origin.row,
        rowLayout: layout.rowLayouts[origin.row],
        font: font,
        appearance: appearance,
        drawRunsProvider: drawRunsProvider
      )

      if 
        drawRuns.cursorDrawRun != nil,
        drawRuns.cursorDrawRun!.position.row == origin.row,
        drawRuns.cursorDrawRun!.position.column >= origin.column,
        drawRuns.cursorDrawRun!.position.column < origin.column + cells.count
      {
        drawRuns.cursorDrawRun!.updateParent(with: layout, rowDrawRuns: drawRuns.rowDrawRuns)
      }

      return .dirtyRectangle(.init(
        origin: origin,
        size: .init(columnsCount: cells.count, rowsCount: 1)
      ))

    case let .scroll(rectangle, offset):
      if offset.columnsCount != 0 {
        assertionFailure("Horizontal scroll not supported")
      }

      drawRunsProvider.clearCache()

      var shouldUpdateCursorDrawRun = false

      let cellsCopy = layout.cells
      let rowLayoutsCopy = layout.rowLayouts
      let rowDrawRunsCopy = drawRuns.rowDrawRuns

      let fromRows = rectangle.minRow ..< rectangle.maxRow
      for fromRow in fromRows {
        let toRow = fromRow - offset.rowsCount

        guard
          toRow >= rectangle.minRow,
          toRow < min(rowsCount, rectangle.maxRow)
        else {
          continue
        }

        layout.cells.rows[toRow] = cellsCopy.rows[fromRow]
        layout.rowLayouts[toRow] = rowLayoutsCopy[fromRow]
        drawRuns.rowDrawRuns[toRow] = rowDrawRunsCopy[fromRow]

        if
          drawRuns.cursorDrawRun != nil,
          drawRuns.cursorDrawRun!.position.row == toRow
        {
          shouldUpdateCursorDrawRun = true
        }
      }

      if shouldUpdateCursorDrawRun {
        drawRuns.cursorDrawRun!.updateParent(with: layout, rowDrawRuns: drawRuns.rowDrawRuns)
      }

      return .dirtyRectangle(.init(origin: rectangle.origin + offset, size: .init(columnsCount: rectangle.size.columnsCount, rowsCount: 1)))

    case .clear:
      layout.cells = .init(size: layout.cells.size, repeatingElement: .default)
      layout.rowLayouts = layout.cells.rows
        .map(RowLayout.init(rowCells:))
      drawRunsProvider.clearCache()
      drawRuns.renderDrawRuns(for: layout, font: font, appearance: appearance, drawRunsProvider: drawRunsProvider)
      drawRuns.cursorDrawRun?.updateParent(with: layout, rowDrawRuns: drawRuns.rowDrawRuns)
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
      return .dirtyRectangle(.init(
        origin: position,
        size: .init(columnsCount: 1, rowsCount: 1)
      ))

    case .clearCursor:
      guard drawRuns.cursorDrawRun != nil else {
        return nil
      }
      let dirtyRectangle = IntegerRectangle(
        origin: drawRuns.cursorDrawRun!.position,
        size: .init(columnsCount: 1, rowsCount: 1)
      )
      drawRuns.cursorDrawRun = nil
      return .dirtyRectangle(dirtyRectangle)
    }
  }

  @Sendable
  public func applyingLineUpdate(forRow row: Int, originColumn: Int, cells: [Cell], font: NimsFont, appearance: Appearance, drawRunsProvider: DrawRunsCachingProvider) async -> LineUpdateResult {
    var rowCells = layout.cells.rows[row]
    rowCells.replaceSubrange(
      originColumn ..< originColumn + cells.count,
      with: cells
    )
    let rowLayout = RowLayout(rowCells: rowCells)
    let rowDrawRun = RowDrawRun(
      row: row,
      rowLayout: rowLayout,
      font: font,
      appearance: appearance,
      drawRunsProvider: drawRunsProvider
    )
    return .init(
      row: row,
      rowCells: rowCells,
      rowLayout: rowLayout,
      rowDrawRun: rowDrawRun,
      dirtyRectangle: .init(
        origin: .init(column: originColumn, row: row),
        size: .init(columnsCount: cells.count, rowsCount: 1)
      ),
      shouldUpdateCursorDrawRun: drawRuns.cursorDrawRun != nil &&
        drawRuns.cursorDrawRun!.position.row == row &&
        drawRuns.cursorDrawRun!.position.column >= originColumn &&
        drawRuns.cursorDrawRun!.position.column < originColumn + cells.count
    )
  }

  @NeovimActor
  public mutating func flushDrawRuns(font: NimsFont, appearance: Appearance) {
    drawRunsProvider.clearCache()
    drawRuns.renderDrawRuns(for: layout, font: font, appearance: appearance, drawRunsProvider: drawRunsProvider)
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
