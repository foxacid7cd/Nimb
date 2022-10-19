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

  var grids = [CellGrid?](repeating: nil, count: 10)
  var font = Font.monospacedSystem(size: 13, weight: .regular)
}

enum StateChange: Hashable {
  case grid(Grid)
  case font

  struct Grid: Hashable {
    enum Change: Hashable {
      case size(GridSize)
      case row(Row)
      case clear
      case destroy

      struct Row: Hashable {
        var origin: GridPoint
        var columnsCount: Int
      }

      var size: GridSize? {
        guard case let .size(model) = self else {
          return nil
        }
        return model
      }

      var row: Row? {
        guard case let .row(model) = self else {
          return nil
        }
        return model
      }

      var isClear: Bool {
        guard case .clear = self else {
          return false
        }
        return true
      }

      var isDestroy: Bool {
        guard case .destroy = self else {
          return false
        }
        return true
      }
    }

    var id: Int
    var change: Change
  }

  var gridID: Int? {
    guard case let .grid(grid) = self else {
      return nil
    }
    return grid.id
  }

  var isFont: Bool {
    guard case .font = self else {
      return false
    }
    return true
  }

  func grid(id: Int) -> Grid.Change? {
    guard case let .grid(grid) = self else {
      return nil
    }
    return grid.change
  }
}
