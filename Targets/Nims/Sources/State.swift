//
//  State.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 19.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Library
import Nvim

struct State: Hashable {
  enum Font: Hashable {
    case monospacedSystem(size: Double, weight: Double)
    case custom(name: String, size: Double)
  }

  struct Window: Hashable {
    var grid: CellGrid
    var origin: GridPoint
    var anchor: Anchor
    var isHidden: Bool
    var zIndex: Int

    var ref: ExtendedTypes.Window?

    var frame: GridRectangle {
      let origin: GridPoint
      switch self.anchor {
      case .bottomLeft:
        origin = .init(
          row: self.origin.row - self.grid.size.rowsCount,
          column: self.origin.column
        )

      case .bottomRight:
        origin = .init(
          row: self.origin.row - self.grid.size.rowsCount,
          column: self.origin.column - self.grid.size.columnsCount
        )

      case .topLeft:
        origin = self.origin

      case .topRight:
        origin = .init(
          row: self.origin.row,
          column: self.origin.column - self.grid.size.columnsCount
        )
      }

      return .init(origin: origin, size: self.grid.size)
    }
  }

  struct Cursor: Hashable {
    var gridID: Int
    var position: GridPoint
  }

  var windows = [Window?](repeating: nil, count: 100)
  var cursor: Cursor?
  var font = Font.custom(name: "JetBrainsMono Nerd Font Mono", size: 13)
  var outerGridSize = GridSize(rowsCount: 40, columnsCount: 120)

  mutating func withMutableWindowIfExists(gridID: Int, _ body: (inout Window) -> Void) {
    guard var window = self.windows[gridID] else {
      return
    }
    body(&window)
    self.windows[gridID] = window
  }
}
