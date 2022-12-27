// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation

public struct IntegerRectangle: Sendable, Equatable {
  public var origin: IntegerPoint
  public var size: IntegerSize

  public init(
    origin: IntegerPoint = .init(),
    size: IntegerSize = .init()
  ) {
    self.origin = origin
    self.size = size
  }
}

public struct IntegerPoint: Sendable, Equatable {
  public var column: Int
  public var row: Int

  public init(
    column: Int = 0,
    row: Int = 0
  ) {
    self.column = column
    self.row = row
  }
}

public struct IntegerSize: Sendable, Equatable {
  public var columnsCount: Int
  public var rowsCount: Int

  public init(
    columnsCount: Int = 0,
    rowsCount: Int = 0
  ) {
    self.columnsCount = columnsCount
    self.rowsCount = rowsCount
  }
}

public func + (lhs: IntegerPoint, rhs: IntegerPoint) -> IntegerPoint {
  .init(column: lhs.column + rhs.column, row: lhs.row + rhs.row)
}

public prefix func - (point: IntegerPoint) -> IntegerPoint {
  .init(column: -point.column, row: -point.row)
}

public func * (first: IntegerPoint, second: CGSize) -> CGPoint {
  .init(x: Double(first.column) * second.width, y: Double(first.row) * second.height)
}

public func * (first: IntegerSize, second: CGSize) -> CGSize {
  .init(
    width: Double(first.columnsCount) * second.width,
    height: Double(first.rowsCount) * second.height
  )
}

public func * (first: IntegerRectangle, second: CGSize) -> CGRect {
  .init(origin: first.origin * second, size: first.size * second)
}

public func + (first: IntegerRectangle, second: IntegerPoint) -> IntegerRectangle {
  .init(origin: first.origin + second, size: first.size)
}
