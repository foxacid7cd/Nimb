//
//  Grid.swift
//  Library
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

public struct Grid<Element> {
  public init(repeating element: Element, size: GridSize) {
    self.init(
      size: size,
      rows: .init(
        repeating: .init(
          repeating: element,
          count: size.columnsCount
        ),
        count: size.rowsCount
      )
    )
  }

  private init(size: GridSize, rows: [[Element]]) {
    self.size = size
    self.rows = rows
  }

  public init(size: GridSize, _ elementAtIndex: (GridPoint) -> Element) {
    self.init(
      size: size,
      rows: (0 ..< size.rowsCount)
        .map { row in
          (0 ..< size.columnsCount)
            .map { column in
              elementAtIndex(
                .init(
                  row: row,
                  column: column
                )
              )
            }
        }
    )
  }

  public typealias Index = GridPoint

  public let size: GridSize

  public var isEmpty: Bool {
    self.size.rowsCount == 0 || self.size.columnsCount == 0
  }

  public subscript(index: GridPoint) -> Element {
    get {
      self.rows[index.row][index.column]
    }
    set(newValue) {
      self.rows[index.row][index.column] = newValue
    }
  }

  public mutating func move(rectangle: GridRectangle, delta: GridPoint) -> GridRectangle {
    let rowRange = max(-delta.row, rectangle.minRow) + delta.row ..< min(self.size.rowsCount, rectangle.maxRow - delta.row) + delta.row
    let columnRange = max(-delta.column, rectangle.minColumn) + delta.column ..< min(self.size.columnsCount, rectangle.maxColumn - delta.column) + delta.column

    var copy = self

    for row in rowRange {
      for column in columnRange {
        let fromIndex = GridPoint(row: row, column: column)

        copy[fromIndex - delta] = self[fromIndex]
      }
    }

    self = copy

    return .init(
      origin: .init(
        row: rowRange.lowerBound,
        column: columnRange.lowerBound
      ),
      size: .init(
        rowsCount: rowRange.upperBound - rowRange.lowerBound,
        columnsCount: columnRange.upperBound - columnRange.lowerBound
      )
    )
  }

  private var rows: [[Element]]
}

extension Grid: Equatable where Element: Equatable {}

extension Grid: Hashable where Element: Hashable {}

public struct GridRectangle: Hashable {
  public init(origin: GridPoint, size: GridSize) {
    self.origin = origin
    self.size = size
  }

  public var origin: GridPoint
  public var size: GridSize

  public var minRow: Int {
    self.origin.row
  }

  public var minColumn: Int {
    self.origin.column
  }

  public var maxRow: Int {
    self.origin.row + self.size.rowsCount
  }

  public var maxColumn: Int {
    self.origin.column + self.size.columnsCount
  }

  public func intersection(_ r2: GridRectangle) -> GridRectangle {
    .init(
      origin: .init(
        row: min(r2.minRow, self.maxRow),
        column: min(r2.minColumn, self.maxColumn)
      ),
      size: .init(
        rowsCount: max(0, r2.maxRow - self.minRow),
        columnsCount: max(0, r2.maxColumn - self.minColumn)
      )
    )
  }
}

public struct GridPoint: Hashable {
  public init(row: Int = 0, column: Int = 0) {
    self.row = row
    self.column = column
  }

  public var row: Int
  public var column: Int
}

public func + (first: GridPoint, second: GridPoint) -> GridPoint {
  .init(row: first.row + second.row, column: first.column + second.column)
}

public func - (first: GridPoint, second: GridPoint) -> GridPoint {
  .init(row: first.row - second.row, column: first.column - second.column)
}

public struct GridSize: Hashable {
  public init(rowsCount: Int = 0, columnsCount: Int = 0) {
    self.rowsCount = rowsCount
    self.columnsCount = columnsCount
  }

  public var rowsCount: Int
  public var columnsCount: Int
}
