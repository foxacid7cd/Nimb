// SPDX-License-Identifier: MIT

public protocol Action: Sendable {
  ///  @StateActor
  func apply(to state: inout State, handleError: @Sendable (Error) -> Void) -> State.Updates
}
