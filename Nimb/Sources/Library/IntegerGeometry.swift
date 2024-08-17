// SPDX-License-Identifier: MIT

import Foundation

@PublicInit
public struct IntegerRectangle: Sendable, Hashable, Codable {
  public var origin: IntegerPoint = .init()
  public var size: IntegerSize = .init()

  @inlinable
  public var minColumn: Int {
    origin.column
  }

  @inlinable
  public var maxColumn: Int {
    origin.column + size.columnsCount
  }

  @inlinable
  public var minRow: Int {
    origin.row
  }

  @inlinable
  public var maxRow: Int {
    origin.row + size.rowsCount
  }

  @inlinable
  public var columns: Range<Int> {
    minColumn ..< maxColumn
  }

  @inlinable
  public var rows: Range<Int> {
    minRow ..< maxRow
  }

  public init(frame: CGRect, cellSize: CGSize) {
    let origin = IntegerPoint(
      column: Int(frame.minX / cellSize.width),
      row: Int(frame.minY / cellSize.height)
    )
    let farthestPoint = IntegerPoint(
      column: Int((frame.maxX / cellSize.width).rounded(.up)),
      row: Int((frame.maxY / cellSize.height).rounded(.up))
    )
    self.init(
      origin: origin,
      size: .init(
        columnsCount: farthestPoint.column - origin.column,
        rowsCount: farthestPoint.row - origin.row
      )
    )
  }

  @inlinable
  public func intersection(with rectangle: IntegerRectangle)
    -> IntegerRectangle
  {
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

  @inlinable
  public mutating func crop(to rectangle: IntegerRectangle) {
    self = intersection(with: rectangle)
  }

  @inlinable
  public func intersects(with rectangle: IntegerRectangle) -> Bool {
    let intersection = intersection(with: rectangle)
    return intersection.size.rowsCount > 0 && intersection.size.columnsCount > 0
  }

  @inlinable
  public func applying(offset: IntegerSize) -> IntegerRectangle {
    .init(origin: origin + offset, size: size)
  }

  @inlinable
  public func contains(_ point: IntegerPoint) -> Bool {
    columns.contains(point.column) && rows.contains(point.row)
  }
}

@inlinable
public func * (first: IntegerRectangle, second: CGSize) -> CGRect {
  .init(origin: first.origin * second, size: first.size * second)
}

@inlinable
public func + (
  first: IntegerRectangle,
  second: IntegerPoint
)
  -> IntegerRectangle
{
  .init(origin: first.origin + second, size: first.size)
}

@PublicInit
public struct IntegerPoint: Sendable, Hashable, Codable {
  public var column: Int = 0
  public var row: Int = 0
}

@inlinable
public func + (lhs: IntegerPoint, rhs: IntegerPoint) -> IntegerPoint {
  .init(column: lhs.column + rhs.column, row: lhs.row + rhs.row)
}

@inlinable
public func + (lhs: IntegerPoint, rhs: IntegerSize) -> IntegerPoint {
  .init(column: lhs.column + rhs.columnsCount, row: lhs.row + rhs.rowsCount)
}

@inlinable
public func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
  .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

@inlinable
public func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
  .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

@inlinable
public prefix func - (point: IntegerPoint) -> IntegerPoint {
  .init(column: -point.column, row: -point.row)
}

@inlinable
public prefix func - (size: IntegerSize) -> IntegerSize {
  .init(columnsCount: -size.columnsCount, rowsCount: -size.rowsCount)
}

@inlinable
public prefix func - (point: CGPoint) -> CGPoint {
  .init(x: -point.x, y: -point.y)
}

@inlinable
public func * (first: IntegerPoint, second: CGSize) -> CGPoint {
  .init(
    x: Double(first.column) * second.width,
    y: Double(first.row) * second.height
  )
}

@PublicInit
public struct IntegerSize: Sendable, Hashable, Codable {
  public var columnsCount: Int = 0
  public var rowsCount: Int = 0
}

@inlinable
public func * (first: IntegerSize, second: CGSize) -> CGSize {
  .init(
    width: Double(first.columnsCount) * second.width,
    height: Double(first.rowsCount) * second.height
  )
}
