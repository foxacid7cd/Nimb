//
//  Store.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Library
import RxSwift

class Store {
  init() {
    let notifications = PublishSubject<[Notification]>()
    self.notifications = notifications
    self.publishNotifications = notifications.onNext(_:)
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
  static var state: State {
    shared.state
  }

  @MainActor
  private(set) var state = State()

  let notifications: Observable<[Notification]>

  @MainActor
  static func changeState<Value>(_ keyPath: WritableKeyPath<State, Value>, _ fn: (inout Value) -> [Notification]) {
    self.shared.changeState(keyPath, fn)
  }

  @MainActor
  func changeState<Value>(_ keyPath: WritableKeyPath<State, Value>, _ fn: (inout Value) -> [Notification]) {
    var state = self.state
    let notifications = fn(&state[keyPath: keyPath])
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

  var grids = [Int: Grid<Cell?>]()
  var currentGridID: Int?
  var cellSize = NSFont(name: "BlexMonoNerdFontCompleteM-", size: 13)!.makeCellSize(for: "A")

  var currentGrid: Grid<Cell?>? {
    self.currentGridID.flatMap { grids[$0] }
  }

  func gridSize(id: Int) -> CGSize {
    let grid = self.grids[id]!

    return .init(
      width: self.cellSize.width * CGFloat(grid.size.columnsCount),
      height: self.cellSize.height * CGFloat(grid.size.rowsCount)
    )
  }

  mutating func change<Value>(_ keyPath: WritableKeyPath<State, Value>, _ fn: (inout Value) -> Void) {
    var state = self
    fn(&state[keyPath: keyPath])
    self = state
  }
}
