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
  init(store: Store) {
    self.store = store
  }

  static let shared = CellsGeometry(store: .shared)

  @MainActor
  var cellSize: CGSize {
    self.store.stateDerivatives.font.cellSize
  }

  @MainActor
  func gridRectangle(cellsRect: CGRect) -> GridRectangle {
    let origin = GridPoint(
      row: Int(floor(cellsRect.minY / self.cellSize.height)),
      column: Int(floor(cellsRect.minX / self.cellSize.width))
    )
    return .init(
      origin: origin,
      size: .init(
        rowsCount: Int(ceil(cellsRect.maxY / self.cellSize.height)) - origin.row,
        columnsCount: Int(ceil(cellsRect.maxX / self.cellSize.width)) - origin.column
      )
    )
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
    .init(
      x: Double(index.column) * self.cellSize.width,
      y: Double(index.row) * self.cellSize.height
    )
  }

  private let store: Store

  @MainActor
  private var state: State {
    self.store.state
  }
}
