//
//  Grid.swift
//  Library
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

public struct Grid<Element>: GridProtocol {
  public init(repeating element: Element, size: GridSize) {
    let rows = Array(
      repeating: Array(
        repeating: element,
        count: size.columnsCount
      ),
      count: size.rowsCount
    )
    self.init(size: size, rows: rows)
  }

  private init(size: GridSize, rows: [[Element]]) {
    self.size = size
    self.rows = rows
  }

  public let size: GridSize

  public subscript(index: GridPoint) -> Element {
    get {
      self.rows[index.row][index.column]
    }
    set(newValue) {
      self.rows = self.rows
        .enumerated()
        .map { offset, row in
          if offset == index.row {
            var row = row
            row[index.column] = newValue
            return row
          }

          return row
        }
    }
  }

  public func subGrid(at rectangle: GridRectangle) -> SubGrid<Element> {
    let rows = self.rows[rectangle.minRow ..< rectangle.maxRow].lazy
      .map { $0[rectangle.minColumn ..< rectangle.maxColumn] }

    return .init(
      size: rectangle.size,
      rows: rows
    )
  }

  public mutating func put<T: GridProtocol>(grid: T, at origin: GridPoint) where T.Element == Element {
    for gridRow in 0 ..< grid.size.rowsCount {
      let row = origin.row + gridRow

      guard row >= 0, row < self.size.rowsCount else {
        continue
      }

      for gridColumn in 0 ..< self.size.columnsCount {
        let column = origin.column + gridColumn

        guard column >= 0, column < self.size.columnsCount else {
          continue
        }

        let index = GridPoint(row: row, column: column)
        let gridIndex = GridPoint(row: gridRow, column: gridColumn)

        self[index] = grid[gridIndex]
      }
    }
  }

  private var rows: [[Element]]
}

extension Grid: Equatable where Element: Equatable {}

extension Grid: Hashable where Element: Hashable {}
