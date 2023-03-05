// SPDX-License-Identifier: MIT

import Foundation
import Neovim

@MainActor @dynamicMemberLookup
final class Store {
  let instance: Instance
  private(set) var state = State()

  private var observers = [UUID: @MainActor (Updates) -> Void]()

  init(instance: Instance) {
    self.instance = instance
  }

  func set(font: NimsFont) {
    state.font = font

    let stateUpdates = State.Updates(isFontUpdated: true)

    for (_, body) in observers {
      body(.init(stateUpdates: stateUpdates))
    }
  }

  func stateUpdatesStream() -> AsyncStream<Updates> {
    .init { continuation in
      let observeWrappedTask = Task {
        for await instanceStateUpdates in instance.stateUpdatesStream() {
          guard !Task.isCancelled else {
            return
          }

          continuation.yield(.init(instanceStateUpdates: instanceStateUpdates))
        }
      }

      let id = UUID()
      observers[id] = { updates in
        continuation.yield(updates)
      }

      continuation.onTermination = { _ in
        observeWrappedTask.cancel()

        Task { @MainActor in
          _ = self.observers.removeValue(forKey: id)
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

  subscript<Value>(dynamicMember keyPath: KeyPath<Neovim.State, Value>) -> Value {
    instance.state[keyPath: keyPath]
  }

  subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
    state[keyPath: keyPath]
  }

  @dynamicMemberLookup
  struct Updates {
    var instanceStateUpdates = Neovim.State.Updates()
    var stateUpdates = State.Updates()

    subscript<Value>(dynamicMember keyPath: KeyPath<Neovim.State.Updates, Value>) -> Value {
      instanceStateUpdates[keyPath: keyPath]
    }

    subscript<Value>(dynamicMember keyPath: KeyPath<State.Updates, Value>) -> Value {
      stateUpdates[keyPath: keyPath]
    }
  }
}
