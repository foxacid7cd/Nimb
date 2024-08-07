// SPDX-License-Identifier: MIT

@MainActor
public class StateContainer: Sendable {
  public nonisolated init(_ state: State) {
    self.state = state
  }

  public var state: State
}
