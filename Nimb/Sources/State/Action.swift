// SPDX-License-Identifier: MIT

public protocol Action: Sendable {
  @StateActor func apply(to container: StateContainer) async throws -> State.Updates
}
