// SPDX-License-Identifier: MIT

import Foundation

public func withAPI(from store: Store, _ body: @escaping @Sendable (API<ProcessChannel>) async throws -> Void) {
  Task {
    try await body(store.api)
  }
}
