//
//  GridGeometry.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import Foundation

struct GridRectangle: Hashable {
  init(origin: GridPoint = .init(), size: GridSize = .init()) {
    self.origin = origin
    self.size = size
  }

  var origin: GridPoint
  var size: GridSize
}

struct GridPoint: Hashable {
  init(x: Int = 0, y: Int = 0) {
    self.x = x
    self.y = y
  }

  var x: Int
  var y: Int
}

func + (first: GridPoint, second: GridPoint) -> GridPoint {
  .init(x: first.x + second.x, y: first.y + second.y)
}

func - (first: GridPoint, second: GridPoint) -> GridPoint {
  .init(x: first.x - second.x, y: first.y - second.y)
}

struct GridSize: Hashable {
  init(width: Int = 0, height: Int = 0) {
    self.width = width
    self.height = height
  }

  var width: Int
  var height: Int
}

func * (first: GridPoint, second: CGSize) -> CGPoint {
  .init(
    x: Double(first.x) * second.width,
    y: Double(first.y) * second.height
  )
}

func * (first: GridSize, second: CGSize) -> CGSize {
  .init(
    width: Double(first.width) * second.width,
    height: Double(first.height) * second.height
  )
}

func * (first: GridRectangle, second: CGSize) -> CGRect {
  .init(
    origin: first.origin * second,
    size: first.size * second
  )
}

func + (first: GridRectangle, second: GridPoint) -> GridRectangle {
  .init(
    origin: first.origin + second,
    size: first.size
  )
}
