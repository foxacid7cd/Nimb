// SPDX-License-Identifier: MIT

public protocol Action: Sendable {
  func apply(to state: inout State, handleError: @Sendable (Error) -> Void) -> State.Updates
}
