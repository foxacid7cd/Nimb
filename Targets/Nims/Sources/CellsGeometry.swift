//
//  CellsGeometry.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 22.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation
import Library

enum CellsGeometry {
  static func upsideDownRect(from rect: CGRect, parentViewHeight: Double) -> CGRect {
    rect.applying(
      self.upsideDownAffineTransform(
        parentViewHeight: parentViewHeight
      )
    )
  }

  static func upsideDownAffineTransform(parentViewHeight: Double) -> CGAffineTransform {
    .identity
      .scaledBy(x: 1, y: -1)
      .translatedBy(x: 0, y: -parentViewHeight)
  }

//  func insetForDrawing(rect: CGRect) -> CGRect {
//    let font = self.store.stateDerivatives.font.regular
//    return rect.insetBy(
//      dx: -(font.boundingRectForFont.width - self.cellSize.width) / 2,
//      dy: -(font.boundingRectForFont.height - self.cellSize.height) / 2
//    )
//  }

  static func gridRectangle(cellsRect: CGRect, cellSize: CGSize) -> GridRectangle {
    let origin = GridPoint(
      row: Int(floor(cellsRect.minY / cellSize.height)),
      column: Int(floor(cellsRect.minX / cellSize.width))
    )
    let size = GridSize(
      rowsCount: Int(ceil(cellsRect.maxY / cellSize.height)) - origin.row,
      columnsCount: Int(ceil(cellsRect.maxX / cellSize.width)) - origin.column
    )
    return GridRectangle(origin: origin, size: size)
  }

  static func cellsRect(for gridRectangle: GridRectangle, cellSize: CGSize) -> CGRect {
    .init(
      origin: self.cellOrigin(for: gridRectangle.origin, cellSize: cellSize),
      size: self.cellsSize(for: gridRectangle.size, cellSize: cellSize)
    )
  }

  static func cellsSize(for gridSize: GridSize, cellSize: CGSize) -> CGSize {
    .init(
      width: Double(gridSize.columnsCount) * cellSize.width,
      height: Double(gridSize.rowsCount) * cellSize.height
    )
  }

  static func cellRect(for index: GridPoint, cellSize: CGSize) -> CGRect {
    .init(
      origin: self.cellOrigin(for: index, cellSize: cellSize),
      size: cellSize
    )
  }

  static func cellOrigin(for index: GridPoint, cellSize: CGSize) -> CGPoint {
    .init(
      x: Double(index.column) * cellSize.width,
      y: Double(index.row) * cellSize.height
    )
  }
}
