// SPDX-License-Identifier: MIT

import Foundation

@PublicInit
public struct NimbNotify: Hashable, Sendable {
  public init(_ value: Value) throws {
    guard
      case let .array(params) = value,
      params.count == 3, case let .string(message) = params[0],
      case let .integer(level) = params[1]
    else {
      throw Failure("Invalid NimbNotifyParams raw value \(value)")
    }
    self.message = message
    self.level = level
    options = params[2]
  }

  public var message: String
  public var level: Int
  public var options: Value
}
