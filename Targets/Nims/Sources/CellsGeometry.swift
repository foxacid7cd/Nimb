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
  @MainActor
  var cellSize: CGSize {
    self.store.stateDerivatives.font.cellSize
  }

  @MainActor
  var outerGridCellsSize: CGSize {
    self.cellsSize(for: self.state.outerGridSize)
  }

  @MainActor
  func insetForDrawing(rect: CGRect) -> CGRect {
    return rect.insetBy(
      dx: -(self.font.boundingRectForFont.width - self.cellSize.width) / 2,
      dy: -(self.font.boundingRectForFont.height - self.cellSize.height) / 2
    )
  }

  @MainActor
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

  @MainActor
  func cellsRect(for gridRectangle: GridRectangle) -> CGRect {
    .init(
      origin: self.cellOrigin(for: gridRectangle.origin),
      size: self.cellsSize(for: gridRectangle.size)
    )
  }

  @MainActor
  func cellsSize(for gridSize: GridSize) -> CGSize {
    .init(
      width: CGFloat(gridSize.columnsCount) * self.cellSize.width,
      height: CGFloat(gridSize.rowsCount) * self.cellSize.height
    )
  }

  @MainActor
  func cellRect(for index: GridPoint) -> CGRect {
    .init(
      origin: self.cellOrigin(for: index),
      size: self.cellSize
    )
  }

  @MainActor
  func cellOrigin(for index: GridPoint) -> CGPoint {
    return .init(
      x: Double(index.column) * self.cellSize.width,
      y: Double(index.row) * self.cellSize.height
    )
  }

  private var store: Store {
    .shared
  }

  @MainActor
  private var state: State {
    self.store.state
  }

  @MainActor
  private var font: NSFont {
    self.store.stateDerivatives.font.nsFont
  }
}
