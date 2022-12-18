// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation

struct Rectangle: Sendable, Equatable {
  init(
    origin: Point = .init(),
    size: Size = .init()
  ) {
    self.origin = origin
    self.size = size
  }

  var origin: Point
  var size: Size
}

struct Point: Sendable, Equatable {
  init(
    column: Int = 0,
    row: Int = 0
  ) {
    self.column = column
    self.row = row
  }

  var column: Int
  var row: Int
}

func + (lhs: Point, rhs: Point) -> Point {
  .init(column: lhs.column + rhs.column, row: lhs.row + rhs.row)
}

prefix func - (point: Point) -> Point { .init(column: -point.column, row: -point.row) }

struct Size: Sendable, Equatable {
  init(
    columnsCount: Int = 0,
    rowsCount: Int = 0
  ) {
    self.columnsCount = columnsCount
    self.rowsCount = rowsCount
  }

  var columnsCount: Int
  var rowsCount: Int
}

func * (first: Point, second: CGSize) -> CGPoint {
  .init(x: Double(first.column) * second.width, y: Double(first.row) * second.height)
}

func * (first: Size, second: CGSize) -> CGSize {
  .init(
    width: Double(first.columnsCount) * second.width,
    height: Double(first.rowsCount) * second.height
  )
}

func * (first: Rectangle, second: CGSize) -> CGRect {
  .init(origin: first.origin * second, size: first.size * second)
}

func + (first: Rectangle, second: Point) -> Rectangle {
  .init(origin: first.origin + second, size: first.size)
}
