// SPDX-License-Identifier: MIT

@StateActor
public class StateContainer: Sendable {
  public nonisolated init(_ state: State) {
    self.state = state
  }

  public var state: State
}
