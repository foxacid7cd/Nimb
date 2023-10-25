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

  public static let OuterID = 1

  public var id: Int
  public var layout: GridLayout
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
      drawRuns.rowDrawRuns = GridDrawRuns.makeDrawRuns(gridLayout: layout, font: font, appearance: appearance, drawRunProvider: drawRuns.drawRunProvider)
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
        drawRunProvider: drawRuns.drawRunProvider
      )
      return .dirtyRectangle(.init(origin: origin, size: .init(columnsCount: cells.count, rowsCount: 1)))

    case let .scroll(rectangle, offset):
      if offset.columnsCount != 0 {
        assertionFailure("Horizontal scroll not supported")
      }

      drawRuns.clearCache()

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
      }
      return .dirtyRectangle(.init(origin: rectangle.origin + offset, size: .init(columnsCount: rectangle.size.columnsCount, rowsCount: 1)))

    case .clear:
      layout.cells = .init(size: layout.cells.size, repeatingElement: .default)
      layout.rowLayouts = layout.cells.rows
        .map(RowLayout.init(rowCells:))
      drawRuns.clearCache()
      drawRuns.rowDrawRuns = GridDrawRuns.makeDrawRuns(gridLayout: layout, font: font, appearance: appearance, drawRunProvider: drawRuns.drawRunProvider)
      return .needsDisplay

    case let .cursor(style, position):
      drawRuns.cursorDrawRun = .init(
        gridLayout: layout,
        rowDrawRuns: drawRuns.rowDrawRuns,
        cursorPosition: position,
        cursorStyle: style,
        font: font,
        appearance: appearance
      )
      return .dirtyRectangle(.init(
        origin: position,
        size: .init(columnsCount: 1, rowsCount: 1)
      ))

    case .clearCursor:
      guard let cursorDrawRun = drawRuns.cursorDrawRun else {
        return nil
      }
      drawRuns.cursorDrawRun = nil
      return .dirtyRectangle(.init(
        origin: cursorDrawRun.position,
        size: .init(columnsCount: 1, rowsCount: 1)
      ))
    }
  }
}
