//
//  State.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 19.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Library

struct State: Hashable {
  enum Font: Hashable {
    case monospacedSystem(size: Double, weight: NSFont.Weight)
    case custom(name: String, size: Double)
  }

  var grids = [CellGrid?](repeating: nil, count: 100)
  var font = Font.monospacedSystem(size: 13, weight: .regular)

  mutating func withMutableGrid(id: Int, _ body: (inout CellGrid) -> Void) {
    body(&self.grids[id]!)
  }
}

enum StateChange: Hashable {
  case grid(Grid)
  case font

  struct Grid: Hashable {
    enum Change: Hashable {
      case size
      case row(Row)
      case scroll(Scroll)
      case clear
      case destroy

      struct Row: Hashable {
        var origin: GridPoint
        var columnsCount: Int
      }

      struct Scroll: Hashable {
        var fromRectangle: GridRectangle
        var toOrigin: GridPoint
      }
    }

    var id: Int
    var change: Change
  }
}
