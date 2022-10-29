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

  public init(size: GridSize, elementAtIndex: (GridPoint) -> Element) {
    var rowsArray = [[Element]]()

    for row in 0 ..< size.rowsCount {
      var rowArray = [Element]()

      for column in 0 ..< size.columnsCount {
        rowArray.append(
          elementAtIndex(.init(row: row, column: column))
        )
      }

      rowsArray.append(rowArray)
    }

    self.size = size
    self.rows = rowsArray
  }

  init(size: GridSize, rows: [[Element]]) {
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
    .init(grid: self, rectangle: rectangle)
  }

  public mutating func put<T: GridProtocol>(grid: T, at origin: GridPoint) where T.Element == Element {
    for gridRow in 0 ..< grid.size.rowsCount {
      let row = origin.row + gridRow

      guard row >= 0, row < self.size.rowsCount else {
        continue
      }

      for gridColumn in 0 ..< grid.size.columnsCount {
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

  public mutating func resize(to newSize: GridSize, fillingEmptyWith element: Element) {
    let newGrid = Self(size: newSize) { index in
      guard index.row < self.size.rowsCount, index.column < self.size.columnsCount else {
        return element
      }

      return self[index]
    }
    self = newGrid
  }

  private var rows: [[Element]]
}

extension Grid: Equatable where Element: Equatable {}

extension Grid: Hashable where Element: Hashable {}
