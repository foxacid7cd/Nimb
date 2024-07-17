// SPDX-License-Identifier: MIT

import CustomDump
import Foundation

public struct Failure: LocalizedError, Sendable {
  public init(filePath: StaticString = #filePath, function: StaticString = #function, line: Int = #line, _ context: Any...) {
    message = context
      .map { object in
        var dump = ""
        customDump(object, to: &dump)
        return dump
      }
      .joined(separator: "\n")
    self.filePath = filePath
    self.function = function
    self.line = line
  }

  public var message: String
  public var filePath: StaticString
  public var function: StaticString
  public var line: Int

  public var errorDescription: String? {
    """
    filePath: \(filePath)
    line: \(line)
    function: \(function)
    message: \(message)
    """
  }
}
