// SPDX-License-Identifier: MIT

import Foundation
import NimbNeovim

public func withAPI(from store: Store, _ body: @escaping @Sendable (API<ProcessChannel>) async throws -> Void) {
  Task {
    try await body(store.api)
  }
}
