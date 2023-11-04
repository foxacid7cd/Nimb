// SPDX-License-Identifier: MIT

import Foundation

protocol Reducer: Sendable {
  func reduce(state: State) async throws -> (state: State, updates: State.Updates)
}
