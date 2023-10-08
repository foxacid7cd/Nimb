// SPDX-License-Identifier: MIT

import CustomDump

public struct Failure: Error, Sendable {
  public init(fileID: StaticString = #fileID, function: StaticString = #function, line: Int = #line, _ context: Any...) {
    message = context
      .map { String(customDumping: $0) }
      .joined(separator: "\n")
    self.fileID = fileID
    self.function = function
    self.line = line
  }

  public var message: String
  public var fileID: StaticString
  public var function: StaticString
  public var line: Int
}
