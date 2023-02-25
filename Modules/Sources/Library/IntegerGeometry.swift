// SPDX-License-Identifier: MIT

import Foundation

public struct IntegerRectangle: Sendable, Hashable {
  public init(
    origin: IntegerPoint = .init(),
    size: IntegerSize = .init()
  ) {
    self.origin = origin
    self.size = size
  }

  public var origin: IntegerPoint
  public var size: IntegerSize

  public var minColumn: Int {
    origin.column
  }

  public var maxColumn: Int {
    origin.column + size.columnsCount
  }

  public var minRow: Int {
    origin.row
  }

  public var maxRow: Int {
    origin.row + size.rowsCount
  }

  public var columns: Range<Int> {
    minColumn ..< maxColumn
  }

  public var rows: Range<Int> {
    minRow ..< maxRow
  }

  public func intersection(with rectangle: IntegerRectangle) -> IntegerRectangle {
    let origin = IntegerPoint(
      column: max(minColumn, rectangle.minColumn),
      row: max(minRow, rectangle.minRow)
    )
    let size = IntegerSize(
      columnsCount: max(0, min(maxColumn, rectangle.maxColumn) - origin.column),
      rowsCount: max(0, min(maxRow, rectangle.maxRow) - origin.row)
    )
    return .init(origin: origin, size: size)
  }
}

public func * (first: IntegerRectangle, second: CGSize) -> CGRect {
  .init(origin: first.origin * second, size: first.size * second)
}

public func + (first: IntegerRectangle, second: IntegerPoint) -> IntegerRectangle {
  .init(origin: first.origin + second, size: first.size)
}

public struct IntegerPoint: Sendable, Hashable {
  public init(
    column: Int = 0,
    row: Int = 0
  ) {
    self.column = column
    self.row = row
  }

  public var column: Int
  public var row: Int
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

public struct IntegerSize: Sendable, Hashable {
  public init(
    columnsCount: Int = 0,
    rowsCount: Int = 0
  ) {
    self.columnsCount = columnsCount
    self.rowsCount = rowsCount
  }

  public var columnsCount: Int
  public var rowsCount: Int
}

public func * (first: IntegerSize, second: CGSize) -> CGSize {
  .init(
    width: Double(first.columnsCount) * second.width,
    height: Double(first.rowsCount) * second.height
  )
}
