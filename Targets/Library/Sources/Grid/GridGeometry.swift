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

  public var rowsRange: Range<Int> {
    self.origin.row ..< self.origin.row + self.size.rowsCount
  }

  public var columnsRange: Range<Int> {
    self.origin.column ..< self.origin.column + self.size.columnsCount
  }

  public func intersection(_ r2: GridRectangle) -> GridRectangle {
    let r1 = self
    return .init(
      origin: .init(
        row: max(r1.origin.row, r2.origin.row),
        column: max(r1.origin.column, r2.origin.column)
      ),
      size: .init(
        rowsCount: min(r1.origin.row + r1.size.rowsCount, r2.origin.row + r2.size.rowsCount) - max(r1.origin.row, r2.origin.row),
        columnsCount: min(r1.origin.column + r1.size.columnsCount, r2.origin.column + r2.size.columnsCount) - max(r1.origin.column, r2.origin.column)
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
