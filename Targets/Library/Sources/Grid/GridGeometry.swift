//
//  GridGeometry.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 23.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation

public struct GridRectangle: Hashable {
  public init(origin: GridPoint = .init(), size: GridSize = .init()) {
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
