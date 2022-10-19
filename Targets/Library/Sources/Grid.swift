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

  public var frame: GridRectangle {
    .init(origin: .init(), size: self.size)
  }

  public subscript(index: GridPoint) -> Element {
    get {
      self.rows[index.row][index.column]
    }
    set(newValue) {
      self.rows[index.row][index.column] = newValue
    }
  }

  public func subGrid(at rectangle: GridRectangle) -> Grid<Element> {
    .init(size: rectangle.size) { index in
      self[index + rectangle.origin]
    }
  }

  public mutating func set(_ subGrid: Grid, at origin: GridPoint) {
    let subGridFrame = GridRectangle(origin: origin, size: subGrid.size)
    precondition(subGridFrame.maxRow < self.frame.maxRow)
    precondition(subGridFrame.maxColumn < self.frame.maxColumn)

    for row in subGridFrame.minRow ... subGridFrame.maxRow {
      for column in subGridFrame.minColumn ... subGridFrame.maxColumn {
        let index = GridPoint(row: row, column: column)
        self[index] = subGrid[index - origin]
      }
    }
  }

  private var rows: [[Element]]
}

extension Grid: CustomLoggable {
  public var logMessage: String {
    return "Grid(rows: \(self.size.rowsCount), columns: \(self.size.columnsCount))"
  }

  public var logChildren: [Any] {
    let description = self.rows
      .map { row in
        row
          .map { String(describing: $0) }
          .joined()
      }
      .joined(separator: "\n")

    return [description]
  }
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
