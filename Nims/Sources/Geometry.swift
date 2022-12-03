// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation

struct Rectangle: Hashable {
  init(origin: Point = .init(), size: Size = .init()) {
    self.origin = origin
    self.size = size
  }

  var origin: Point
  var size: Size
}

struct Point: Hashable {
  init(x: Int = 0, y: Int = 0) {
    self.x = x
    self.y = y
  }

  var x: Int
  var y: Int
}

func + (lhs: Point, rhs: Point) -> Point {
  .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

prefix func - (point: Point) -> Point {
  .init(x: -point.x, y: -point.y)
}

struct Size: Hashable {
  init(width: Int = 0, height: Int = 0) {
    self.width = width
    self.height = height
  }

  var width: Int
  var height: Int
}

func * (first: Point, second: CGSize) -> CGPoint {
  .init(
    x: Double(first.x) * second.width,
    y: Double(first.y) * second.height
  )
}

func * (first: Size, second: CGSize) -> CGSize {
  .init(
    width: Double(first.width) * second.width,
    height: Double(first.height) * second.height
  )
}

func * (first: Rectangle, second: CGSize) -> CGRect {
  .init(
    origin: first.origin * second,
    size: first.size * second
  )
}

func + (first: Rectangle, second: Point) -> Rectangle {
  .init(
    origin: first.origin + second,
    size: first.size
  )
}
