// SPDX-License-Identifier: MIT

public protocol Action: Sendable {
  @MainActor
  func apply(to container: StateContainer) async throws -> State.Updates
}
