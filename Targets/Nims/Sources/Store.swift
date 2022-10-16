//
//  Store.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import API
import AppKit
import AsyncAlgorithms
import Library

class Store {
  struct State {
    var grids = [Int: Grid<Cell?>]()
    var cellSize = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular).makeCellSize(for: "A")
  }

  struct Cell {
    var text: String?
    var hlID: UInt
  }

  enum Notification {
    case gridCreated(id: Int)
    case gridUpdated(id: Int, updates: GridUpdates)
    case gridDestroyed(id: Int)

    enum GridUpdates {
      case line(row: Int, columnStart: Int, cellsCount: Int)
    }
  }

  @MainActor
  private(set) var state = State()

  var notifications: AnyAsyncSequence<[Notification]> {
    .init(channel: self.notificationsChannel)
  }

  @MainActor
  func mutateState(_ fn: (inout State) -> [Notification]) {
    var state = self.state
    let notifications = fn(&state)
    self.state = state

    Task {
      await notificationsChannel.send(notifications)
    }
  }

  private let notificationsChannel = AsyncChannel<[Notification]>()
}
