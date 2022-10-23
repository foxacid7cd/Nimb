//
//  Grid.swift
//  Library
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

public struct Grid<Element> {
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

  public mutating func move(rectangle: GridRectangle, delta: GridPoint) -> GridRectangle {
    let rowLowerBound = max(-min(0, delta.row), max(-delta.row, rectangle.origin.row - delta.row) + delta.row)
    let rowUpperBound = -min(0, -min(self.size.rowsCount, min(rectangle.maxRow + delta.row, rectangle.maxRow))) - max(0, delta.row)

    let columnLowerBound = max(-min(0, delta.column), max(-delta.column, rectangle.origin.column - delta.column) + delta.column)
    let columnUpperBound = -min(0, -min(self.size.columnsCount, min(rectangle.maxColumn + delta.column, rectangle.maxColumn))) - max(0, delta.column)

    let copy = self

    for row in rowLowerBound ..< rowUpperBound {
      for column in columnLowerBound ..< columnUpperBound {
        let index = GridPoint(row: row, column: column)

        self[index] = copy[index + delta]
      }
    }

    return .init(
      origin: .init(
        row: rowLowerBound,
        column: columnLowerBound
      ),
      size: .init(
        rowsCount: rowUpperBound - rowLowerBound,
        columnsCount: columnUpperBound - columnLowerBound
      )
    )
  }

  private var rows: [[Element]]
}

extension Grid: Equatable where Element: Equatable {}

extension Grid: Hashable where Element: Hashable {}
