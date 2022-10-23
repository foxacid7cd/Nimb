//
//  CellsGeometry.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 22.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation
import Library

final class CellsGeometry {
  init(gridID: Int) {
    self.gridID = gridID
  }

  @MainActor
  var cellSize: CGSize {
    self.store.stateDerivatives.font.cellSize
  }

  @MainActor
  var gridCellsSize: CGSize {
    .init(
      width: Double(self.grid.size.columnsCount) * self.cellSize.width,
      height: Double(self.grid.size.rowsCount) * self.cellSize.height
    )
  }

  @MainActor
  func gridRectangle(cellsRect: CGRect) -> GridRectangle {
    let origin = GridPoint(
      row: self.grid.size.rowsCount - 1 - Int(floor(cellsRect.minY / self.cellSize.height)),
      column: Int(floor(cellsRect.minX / self.cellSize.width))
    )
    let size = GridSize(
      rowsCount: Int(ceil(cellsRect.maxY / self.cellSize.height)) - origin.row,
      columnsCount: Int(ceil(cellsRect.maxX / self.cellSize.width)) - origin.column
    )
    return .init(origin: origin, size: size)
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
      y: Double(self.grid.size.rowsCount - 1 - index.row) * self.cellSize.height
    )
  }

  private let gridID: Int

  private var store: Store {
    .shared
  }

  @MainActor
  private var state: State {
    self.store.state
  }

  @MainActor
  private var grid: CellGrid {
    self.state.grids[self.gridID]!
  }
}
