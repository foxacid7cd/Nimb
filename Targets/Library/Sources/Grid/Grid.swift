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

  public mutating func moveRows(originRow: Int, rowsCount: Int, delta: Int) {
    let copy = self

    for row in originRow ..< originRow + rowsCount {
      let newRow = row - delta

      guard newRow >= 0, newRow < self.size.rowsCount else {
        continue
      }

      self.rows[newRow] = copy.rows[row]
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
