// SPDX-License-Identifier: MIT

import OSLog

private let subsystem = Bundle.main.bundleIdentifier!

enum Loggers {
  static let uiEvents = Logger(subsystem: subsystem, category: "UI Events")
  static let problems = Logger(subsystem: subsystem, category: "Problems")
}
