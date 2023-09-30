// SPDX-License-Identifier: MIT

import CustomDump

public struct Failure: Error, Sendable {
  public init(_ message: Message, fileID: StaticString = #fileID, function: StaticString = #function, line: Int = #line) {
    self.message = message
    self.fileID = fileID
    self.function = function
    self.line = line
  }

  public struct Message: Hashable, Sendable {
    var rawValue: String
  }

  public var message: Message
  public var fileID: StaticString
  public var function: StaticString
  public var line: Int
}

extension Failure.Message: ExpressibleByStringInterpolation {
  public init(stringLiteral value: String) {
    rawValue = value
  }

  public init(stringInterpolation: StringInterpolation) {
    rawValue = stringInterpolation.messageComponents
      .joined()
  }

  public struct StringInterpolation: StringInterpolationProtocol {
    public init(literalCapacity: Int, interpolationCount: Int) {
      messageComponents = []
    }

    public mutating func appendLiteral(_ literal: String) {
      messageComponents.append(literal)
    }

    public mutating func appendInterpolation(_ value: some Any) {
      var description = ""
      customDump(value, to: &description)

      messageComponents.append(description)
    }

    var messageComponents: [String]
  }
}
