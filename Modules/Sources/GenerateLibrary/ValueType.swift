// SPDX-License-Identifier: MIT

public struct ValueType: Sendable {
  public var rawValue: String
  public var custom: Custom?

  public struct Custom: Sendable {
    public var signature: String
    public var valueEncoder: (prefix: String, suffix: String)
    public var valueDecoder: (prefix: String, suffix: String)
  }

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

  public var swift: SwiftType {
    if let custom {
      return .custom(custom)

    } else if rawValue.starts(with: "Array") {
      return .array

    } else if rawValue == "Dictionary" {
      return .dictionary

    } else if ["Integer", "LuaRef"].contains(rawValue) {
      return .integer

    } else if rawValue == "Float" {
      return .float

    } else if rawValue == "String" {
      return .string

    } else if rawValue == "Boolean" {
      return .boolean

    } else {
      return .value
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

  public func wrapWithValueDecoder(_ expr: String, force: Bool = false) -> String {
    let forceUnwrapSuffix = force ? "!" : ""

    switch swift {
    case .integer:
      return "(/Value.integer).extract(from: \(expr))\(forceUnwrapSuffix)"

    case .float:
      return "(/Value.float).extract(from: \(expr))\(forceUnwrapSuffix)"

    case .string:
      return "(/Value.string).extract(from: \(expr))\(forceUnwrapSuffix)"

    case .boolean:
      return "(/Value.boolean).extract(from: \(expr))\(forceUnwrapSuffix)"

    case .dictionary:
      return "(/Value.dictionary).extract(from: \(expr))\(forceUnwrapSuffix)"

    case .array:
      return "(/Value.array).extract(from: \(expr))\(forceUnwrapSuffix)"

    case .binary:
      return "(/Value.binary).extract(from: \(expr))\(forceUnwrapSuffix)"

    case let .custom(custom):
      return custom.valueDecoder.prefix + expr + custom.valueDecoder.suffix + forceUnwrapSuffix

    case .value:
      return expr
    }
  }
}
