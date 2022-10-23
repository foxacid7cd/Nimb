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

  struct Grid: Hashable {
    struct Window: Hashable {
      var frame: GridRectangle
      var isHidden: Bool
    }

    var cellGrid: CellGrid
    var windows: [ExtendedTypes.Window: Window]

    mutating func withMutableWindow(ref: ExtendedTypes.Window, _ body: (inout Window?) -> Void) {
      body(&self.windows[ref])
    }
  }

  struct Cursor: Hashable {
    var gridID: Int
    var index: GridPoint
  }

  var outerGridSize = GridSize(rowsCount: 40, columnsCount: 110)
  var grids = [Grid?](repeating: nil, count: 100)
  var cursor: Cursor?
  var font = Font.monospacedSystem(size: 13, weight: 0)

  mutating func withMutableGrid(id: Int, _ body: (inout Grid?) -> Void) {
    body(&self.grids[id])
  }
}

enum StateChange: Hashable {
  case grid(Grid)
  case window(Window)
  case cursor(State.Cursor)
  case font

  struct Grid: Hashable {
    enum Change: Hashable {
      case size
      case row(Row)
      case rectangle(GridRectangle)
      case clear
      case destroy

      struct Row: Hashable {
        var origin: GridPoint
        var columnsCount: Int
      }
    }

    var id: Int
    var change: Change
  }

  struct Window: Hashable {
    enum Change: Hashable {
      case position
      case externalPosition
      case hide
      case close
    }

    var gridID: Int
    var ref: ExtendedTypes.Window
    var change: Change
  }
}
