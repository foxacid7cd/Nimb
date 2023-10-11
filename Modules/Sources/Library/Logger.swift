// SPDX-License-Identifier: MIT

import OSLog

public extension Logger {
  private static let subsystem = Bundle.main.bundleIdentifier!

  static let rpc = Logger(subsystem: subsystem, category: "RPC")
}
