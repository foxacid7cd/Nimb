// SPDX-License-Identifier: MIT

import OSLog

let logger = Logger(subsystem: "foxacid7cd.Nimb", category: "General")

func lastLogEntries() async throws -> String {
  let store = try OSLogStore(scope: .currentProcessIdentifier)
  let position = store.position(
    date: Date.now.addingTimeInterval(-5.0 * 60.0)
  )
  let entries = try store.getEntries(at: position)
  return entries.map(\.composedMessage).joined(separator: "\n")
}
