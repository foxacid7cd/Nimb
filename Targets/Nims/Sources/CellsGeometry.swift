//
//  CellsGeometry.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 22.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Library

final class CellsGeometry {
  static let shared = CellsGeometry()

  var outerCellsSize: CGSize {
    self.cellsSize(for: self.state.outerGridSize)
  }

  var cellSize: CGSize {
    self.store.stateDerivatives.font.cellSize
  }

  func upsideDownRect(from rect: CGRect, parentViewHeight: CGFloat) -> CGRect {
    rect.applying(
      self.upsideDownAffineTransform(
        parentViewHeight: parentViewHeight
      )
    )
  }

  func upsideDownAffineTransform(parentViewHeight: CGFloat) -> CGAffineTransform {
    .identity
      .scaledBy(x: 1, y: -1)
      .translatedBy(x: 0, y: -parentViewHeight)
  }

  func gridCellsSize(grid: Grid<Cell?>) -> CGSize {
    self.cellsSize(for: grid.size)
  }

  func insetForDrawing(rect: CGRect) -> CGRect {
    let font = self.store.stateDerivatives.font.regular
    return rect.insetBy(
      dx: -(font.boundingRectForFont.width - self.cellSize.width) / 2,
      dy: -(font.boundingRectForFont.height - self.cellSize.height) / 2
    )
  }

  func gridRectangle(cellsRect: CGRect) -> GridRectangle {
    let origin = GridPoint(
      row: Int(floor(cellsRect.minY / self.cellSize.height)),
      column: Int(floor(cellsRect.minX / self.cellSize.width))
    )
    let size = GridSize(
      rowsCount: Int(ceil(cellsRect.maxY / self.cellSize.height)) - origin.row,
      columnsCount: Int(ceil(cellsRect.maxX / self.cellSize.width)) - origin.column
    )
    return GridRectangle(origin: origin, size: size)
  }

  func cellsRect(for gridRectangle: GridRectangle) -> CGRect {
    .init(
      origin: self.cellOrigin(for: gridRectangle.origin),
      size: self.cellsSize(for: gridRectangle.size)
    )
  }

  func cellsSize(for gridSize: GridSize) -> CGSize {
    .init(
      width: CGFloat(gridSize.columnsCount) * self.cellSize.width,
      height: CGFloat(gridSize.rowsCount) * self.cellSize.height
    )
  }

  func cellRect(for index: GridPoint) -> CGRect {
    .init(
      origin: self.cellOrigin(for: index),
      size: self.cellSize
    )
  }

  func cellOrigin(for index: GridPoint) -> CGPoint {
    .init(
      x: Double(index.column) * self.cellSize.width,
      y: Double(index.row) * self.cellSize.height
    )
  }

  private var store: Store {
    .shared
  }

  private var state: State {
    self.store.state
  }
}
