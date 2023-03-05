// SPDX-License-Identifier: MIT

import Foundation
import Neovim

@MainActor
final class Store {
  public private(set) var state: State

  private let instance: Instance
  private var observers = [UUID: @MainActor (State.Updates) -> Void]()

  init(instance: Instance) {
    state = .init(instance: instance)
    self.instance = instance
  }

  func set(font: NimsFont) {
    state.font = font

    let updates = State.Updates(isFontUpdated: true)

    for (_, body) in observers {
      body(updates)
    }
  }

  func stateUpdatesStream() -> AsyncStream<State.Updates> {
    .init { continuation in
      let observeWrappedTask = Task {
        for await instanceStateUpdates in instance.stateUpdatesStream() {
          continuation.yield(.init(wrapped: instanceStateUpdates))
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

  @MainActor @dynamicMemberLookup
  struct State: Sendable {
    var instance: Instance
    var font = NimsFont()

    subscript<Value>(dynamicMember keyPath: KeyPath<Neovim.State, Value>) -> Value {
      instance.state[keyPath: keyPath]
    }

    @dynamicMemberLookup
    struct Updates: Sendable {
      var wrapped = Neovim.State.Updates()
      var isFontUpdated = false

      subscript<Value>(dynamicMember keyPath: KeyPath<Neovim.State.Updates, Value>) -> Value {
        wrapped[keyPath: keyPath]
      }
    }
  }
}
