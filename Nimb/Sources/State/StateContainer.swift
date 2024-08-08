// SPDX-License-Identifier: MIT

@MainActor
public class StateContainer: Sendable {
  public init(state: State) {
    self.state = state
  }

  public private(set) var state: State

  public func apply(updates: State.Updates, from state: State) {
    self.state.apply(updates: updates, from: state)
  }
}
