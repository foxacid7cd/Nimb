// Copyright © 2022 foxacid7cd. All rights reserved.

private let DictionaryTypes: Set = ["Object", "Dictionary"]
private let IntegerTypes: Set = ["Buffer", "Integer", "LuaRef", "Tabpage", "Window"]

public struct ValueType: Hashable {
  public enum SwiftType {
    case integer
    case float
    case string
    case boolean
    case dictionary
    case array
    case binary
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

      case .value:
        return "Value"
      }
    }
  }

  public var metadataString: String

  public var swift: SwiftType {
    if metadataString.starts(with: "Array") {
      return .array

    } else if DictionaryTypes.contains(metadataString) {
      return .dictionary

    } else if IntegerTypes.contains(metadataString) {
      return .integer

    } else if metadataString == "Float" {
      return .float

    } else if metadataString == "String" {
      return .string

    } else if metadataString == "Boolean" {
      return .boolean

    } else {
      return .value
    }
  }

  public func wrapExprWithValueEncoder(_ expr: String) -> String {
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

    case .value:
      return expr
    }
  }

  public func wrapWithValueDecoder(_ expr: String) -> String {
    switch swift {
    case .integer:
      return "\(expr)[/Value.integer]"

    case .float:
      return "\(expr)[/Value.float]"

    case .string:
      return "\(expr)[/Value.string]"

    case .boolean:
      return "\(expr)[/Value.boolean]"

    case .dictionary:
      return "\(expr)[/Value.dictionary]"

    case .array:
      return "\(expr)[/Value.array]"

    case .binary:
      return "\(expr)[/Value.binary]"

    case .value:
      return expr
    }
  }
}
