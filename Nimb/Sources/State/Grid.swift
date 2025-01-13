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
    public var dirtyRectangles: [IntegerRectangle]
  }

  public static let OuterID = 1

  public var id: Int
  public var layout: GridLayout
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
      repeatingElement: Cell.default
    ))

    self.id = id
    self.layout = layout
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
        repeatingElement: .default
      )
      for row in 0 ..< copyRowsCount {
        cells.rows[row].replaceSubrange(
          copyColumnsRange,
          with: layout.cells.rows[row][copyColumnsRange]
        )
      }
      layout = .init(cells: cells)

      return .needsDisplay

    case let .scroll(rectangle, offset):
      if offset.columnsCount != 0 {
        Task { @MainActor in
          logger.error("horizontal scroll not supported!!!")
        }
      }

      let cellsCopy = layout.cells
      let rowLayoutsCopy = layout.rowLayouts

      let toRectangle = rectangle
        .applying(offset: -offset)
        .intersection(with: rectangle)

      for toRow in toRectangle.rows {
        let fromRow = toRow + offset.rowsCount

        if rectangle.size.columnsCount == size.columnsCount {
          layout.cells.rows[toRow] = cellsCopy.rows[fromRow]
          layout.rowLayouts[toRow] = rowLayoutsCopy[fromRow]
        } else {
          layout.cells.rows[toRow].replaceSubrange(
            rectangle.columns,
            with: cellsCopy.rows[fromRow][rectangle.columns]
          )
          layout.rowLayouts[toRow] = .init(rowCells: layout.cells.rows[toRow])
        }
      }

      return .dirtyRectangles([toRectangle])

    case .clear:
      layout.cells = .init(size: layout.cells.size, repeatingElement: .default)
      layout.rowLayouts = layout.cells.rows
        .map(RowLayout.init(rowCells:))
      return .needsDisplay

    case let .cursor(_, position):
      let columnsCount =
        if
          position.row < layout.rowLayouts.count,
          let rowPart = layout.rowLayouts[position.row].parts
            .first(where: { $0.columnsRange.contains(position.column) }),
            position.column < rowPart.columnsCount,
            let rowPartCell = rowPart.cells
              .first(where: {
                (
                  (
                    $0.columnsRange.lowerBound + rowPart.columnsRange
                      .lowerBound
                  ) ..<
                    ($0.columnsRange.upperBound + rowPart.columnsRange.lowerBound)
                ).contains(position.column)
              })
        {
          rowPartCell.columnsRange.count
        } else {
          1
        }

      return .dirtyRectangles([.init(
        origin: position,
        size: .init(columnsCount: columnsCount, rowsCount: 1)
      )])

    case .clearCursor:
      return .dirtyRectangles([])
    }
  }

  @Sendable
  public func applying(
    lineUpdates: [(originColumn: Int, cells: [Cell])],
    forRow row: Int,
    font: Font,
    appearance: Appearance
  )
    -> LineUpdatesResult
  {
    var dirtyRectangles = [IntegerRectangle]()

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
    }
    let rowLayout = RowLayout(rowCells: rowCells)
    return .init(
      row: row,
      rowCells: rowCells,
      rowLayout: rowLayout,
      dirtyRectangles: dirtyRectangles
    )
  }
}
