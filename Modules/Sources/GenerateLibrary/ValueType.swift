// SPDX-License-Identifier: MIT

import CasePaths

public struct ValueType: Sendable {
  public struct Custom: Sendable {
    public var signature: String
    public var valueEncoder: (prefix: String, suffix: String)
    public var valueDecoder: @Sendable (_ expr: String, _ name: String) -> String
  }

  @CasePathable
  public enum SwiftType {
    case integer
    case float
    case string
    case boolean
    case dictionary
    case array
    case binary
    case custom(Custom)
    case value

    public var signature: String {
      switch self {
      case .integer:
        "Int"

      case .float:
        "Double"

      case .string:
        "String"

      case .boolean:
        "Bool"

      case .dictionary:
        "[Value: Value]"

      case .array:
        "[Value]"

      case .binary:
        "Data"

      case let .custom(custom):
        custom.signature

      case .value:
        "Value"
      }
    }
  }

  public var rawValue: String
  public var custom: Custom?

  public var swift: SwiftType {
    if let custom {
      .custom(custom)

    } else if rawValue.starts(with: "Array") {
      .array

    } else if rawValue == "Dictionary" {
      .dictionary

    } else if ["Integer", "LuaRef"].contains(rawValue) {
      .integer

    } else if rawValue == "Float" {
      .float

    } else if rawValue == "String" {
      .string

    } else if rawValue == "Boolean" {
      .boolean

    } else {
      .value
    }
  }

  public func wrapWithValueEncoder(_ expr: String) -> String {
    switch swift {
    case .integer:
      ".integer(\(expr))"

    case .float:
      ".float(\(expr))"

    case .string:
      ".string(\(expr))"

    case .boolean:
      ".boolean(\(expr))"

    case .dictionary:
      ".dictionary(\(expr))"

    case .array:
      ".array(\(expr))"

    case .binary:
      ".binary(\(expr))"

    case let .custom(custom):
      custom.valueEncoder.prefix + expr + custom.valueEncoder.suffix

    case .value:
      expr
    }
  }

  public func wrapWithValueDecoder(_ expr: String, name: String) -> String {
    switch swift {
    case .integer:
      "case let .integer(\(name)) = \(expr)"

    case .float:
      "case let .float(\(name)) = \(expr)"

    case .string:
      "case let .string(\(name)) = \(expr)"

    case .boolean:
      "case let .boolean(\(name)) = \(expr)"

    case .dictionary:
      "case let .dictionary(\(name)) = \(expr)"

    case .array:
      "case let .array(\(name)) = \(expr)"

    case .binary:
      "case let .binary(\(name)) = \(expr)"

    case let .custom(custom):
      custom.valueDecoder(expr, name)

    case .value:
      expr
    }
  }
}
