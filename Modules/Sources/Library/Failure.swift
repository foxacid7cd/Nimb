// SPDX-License-Identifier: MIT

import CustomDump
import Foundation

public struct Failure: LocalizedError, Sendable {
  public init(
    fileID: StaticString = #fileID,
    function: StaticString = #function,
    line: Int = #line,
    _ context: Any...
  ) {
    message = context
      .map { object in
        var dump = ""
        customDump(object, to: &dump)
        return dump
      }
      .joined(separator: "\n")
    self.fileID = fileID
    self.function = function
    self.line = line
  }

  public var fileID: StaticString
  public var line: Int
  public var function: StaticString
  public var message: String

  public var errorDescription: String? {
    """
    fileID: \(fileID)
    line: \(line)
    function: \(function)
    message: \(message)
    """
  }
}
