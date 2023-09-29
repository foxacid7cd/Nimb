// SPDX-License-Identifier: MIT

import Foundation
import Library
import Neovim

@MainActor
@dynamicMemberLookup
final class Store {
  let instance: Instance
  let cursorBlinker: CursorBlinker
  private(set) var state = State()

  private var observers = [UUID: @MainActor (Updates) -> Void]()
  private var observeCursorUpdatesTask: Task<Void, Never>?

  init(instance: Instance, cursorBlinker: CursorBlinker) {
    self.instance = instance
    self.cursorBlinker = cursorBlinker

    cursorBlinker.observer = { [weak self] in
      guard let self, let cursor = self.instance.state.cursor else {
        return
      }

      let cursorFrame = IntegerRectangle(
        origin: cursor.position,
        size: .init(columnsCount: 1, rowsCount: 1)
      )
      let updates = Store.Updates(
        instanceStateUpdates: .init(
          isCursorUpdated: true,
          gridUpdatedRectangles: [cursor.gridID: [cursorFrame]]
        )
      )
      self.observers
        .forEach { $1(updates) }
    }

    cursorBlinker.cursorUpdated(state: instance.state)

    let stateUpdatesStream = instance.stateUpdatesStream()
    observeCursorUpdatesTask = Task { @MainActor [weak self] in
      for await updates in stateUpdatesStream {
        guard !Task.isCancelled else {
          break
        }

        if updates.isCursorUpdated, let state = self?.instance.state {
          self?.cursorBlinker.cursorUpdated(state: state)
        }
      }
    }
  }

  deinit {
    observeCursorUpdatesTask?.cancel()
  }

  func set(font: NimsFont) {
    state.font = font

    let stateUpdates = State.Updates(isFontUpdated: true)

    for (_, body) in observers {
      body(.init(stateUpdates: stateUpdates))
    }
  }

  func stateUpdatesStream() -> AsyncStream<Updates> {
    .init { [weak self] continuation in
      let observeWrappedTask = Task {
        guard let self else {
          return
        }

        for await instanceStateUpdates in self.instance.stateUpdatesStream() {
          guard !Task.isCancelled else {
            return
          }

          continuation.yield(.init(instanceStateUpdates: instanceStateUpdates))
        }

        continuation.finish()
      }

      let id = UUID()
      self?.observers[id] = { updates in
        continuation.yield(updates)
      }

      continuation.onTermination = { _ in
        observeWrappedTask.cancel()

        Task { @MainActor in
          self?.observers.removeValue(forKey: id)
        }
      }
    }
  }

  func report(keyPress: KeyPress) async {
    await instance.report(keyPress: keyPress)
  }

  func report(mouseEvent: MouseEvent) async {
    await instance.report(mouseEvent: mouseEvent)
  }

  var cursor: Cursor? {
    cursorBlinker.cursorBlinkingPhase ? instance.state.cursor : nil
  }

  subscript<Value>(dynamicMember keyPath: KeyPath<Neovim.State, Value>) -> Value {
    instance.state[keyPath: keyPath]
  }

  subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
    state[keyPath: keyPath]
  }

  @PublicInit
  @dynamicMemberLookup
  struct Updates: Sendable {
    var instanceStateUpdates: Neovim.State.Updates = .init()
    var stateUpdates: State.Updates = .init()

    subscript<Value>(dynamicMember keyPath: KeyPath<Neovim.State.Updates, Value>) -> Value {
      instanceStateUpdates[keyPath: keyPath]
    }

    subscript<Value>(dynamicMember keyPath: KeyPath<State.Updates, Value>) -> Value {
      stateUpdates[keyPath: keyPath]
    }
  }
}
