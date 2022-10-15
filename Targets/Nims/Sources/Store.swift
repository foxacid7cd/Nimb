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
    struct Grid: Identifiable {
      var id: Int
      var width: Int
      var height: Int
    }

    var grids = [Grid.ID: Grid]()
    var currentGridID: Grid.ID?
    var cellSize = CGSize(width: 12, height: 24)
  }

  @Published private(set) var state = State()

  @MainActor
  func dispatch(_ action: (inout State) -> Void) {
    action(&self.state)
  }
}
