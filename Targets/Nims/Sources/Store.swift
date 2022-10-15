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
    var cellSize = CGSize(width: 12, height: 24)
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

  var notifications: AnyAsyncSequence<Notification> {
    .init(channel: self.notificationsChannel)
  }

  @MainActor
  func mutateState(_ fn: (inout State) -> [Notification]) {
    let notifications = fn(&self.state)

    Task {
      for notification in notifications {
        await notificationsChannel.send(notification)
      }
    }
  }

  private let notificationsChannel = AsyncChannel<Notification>()
}
