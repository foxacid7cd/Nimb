//
//  Store.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import API
import AppKit
import Combine
import Library

class Store: ObservableObject {
  struct State {
    struct Cell {
      var character: Character?
      var hlID: UInt
    }

    struct Grid: Identifiable {
      var id: Int
      var width: Int
      var height: Int
      var cells: [Cell?]

      init(id: Int, width: Int, height: Int) {
        self.id = id
        self.width = width
        self.height = height
        self.cells = .init(repeating: nil, count: width * height)
      }
    }

    var grids = [Grid?]()
    var currentGridIndex: Int?
    var cellSize = CGSize(width: 12, height: 24)

    var currentGrid: Grid? {
      currentGridIndex.flatMap { grids[$0] }
    }
  }

  @Published @MainActor private(set) var state = State()

  @MainActor
  func dispatch(_ action: (inout State) -> Void) {
    action(&state)
  }
}

extension Array where Element == Store.State.Grid? {
  mutating func ensureIndexInBounds(_ index: Int) {
    while count < index {
      self += .init(repeating: nil, count: isEmpty ? 10 : count)
    }
  }
}
