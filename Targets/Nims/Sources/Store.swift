//
//  Store.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Combine
import Library

class Store {
  init() {
    let notifications = PassthroughSubject<[Notification], Never>()
    self.notifications = notifications
      .share()
      .eraseToAnyPublisher()
    self.publishNotifications = { notifications.send($0) }
  }

  enum Notification {
    case gridCreated(id: Int)
    case gridUpdated(id: Int, updates: GridUpdates)
    case gridDestroyed(id: Int)
    case currentGridChanged

    enum GridUpdates {
      case line(row: Int, columnStart: Int, cellsCount: Int)
    }
  }

  static let shared = Store()

  @MainActor
  private(set) var state = State()

  let notifications: AnyPublisher<[Notification], Never>

  @MainActor
  func mutateState(_ fn: (inout State) -> [Notification]) {
    var state = self.state
    let notifications = fn(&state)
    self.state = state

    Task {
      self.publishNotifications(notifications)
    }
  }

  private let publishNotifications: ([Notification]) -> Void
}

struct State {
  struct Cell {
    var character: Character?
    var hlID: Int
  }

  @MainActor
  static var shared: State {
    Store.shared.state
  }

  var grids = [Int: Grid<Cell?>]()
  var currentGridID: Int?
  var cellSize = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular).makeCellSize(for: "A")

  var currentGrid: Grid<Cell?>? {
    self.currentGridID.flatMap { grids[$0] }
  }

  func gridSize(id: Int) -> CGSize {
    let grid = self.grids[id]!

    return .init(
      width: self.cellSize.width * CGFloat(grid.columnsCount),
      height: self.cellSize.height * CGFloat(grid.rowsCount)
    )
  }
}
