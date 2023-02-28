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
        return "Int"

      case .float:
        return "Double"

      case .string:
        return "String"

      case .boolean:
        return "Bool"

      case .dictionary:
        return "[Value: Value]"

      case .array:
        return "[Value]"

      case .binary:
        return "Data"

      case let .custom(custom):
        return custom.signature

      case .value:
        return "Value"
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
      return ".integer(\(expr))"

    case .float:
      return ".float(\(expr))"

    case .string:
      return ".string(\(expr))"

    case .boolean:
      return ".boolean(\(expr))"

    case .dictionary:
      return ".dictionary(\(expr))"

    case .array:
      return ".array(\(expr))"

    case .binary:
      return ".binary(\(expr))"

    case let .custom(custom):
      return custom.valueEncoder.prefix + expr + custom.valueEncoder.suffix

    case .value:
      return expr
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
