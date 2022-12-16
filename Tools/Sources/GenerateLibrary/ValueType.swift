// Copyright © 2022 foxacid7cd. All rights reserved.

private let DictionaryTypes: Set = ["Object", "Dictionary"]
private let IntegerTypes: Set = ["Integer", "LuaRef"]

public struct ValueType: Hashable {
  public enum SwiftType: String {
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

  public func wrapWithValueEncoder(_ expr: String) -> String {
    switch swift {
    case .value:
      return expr

    default:
      return ".\(swift.rawValue)(\(expr))"
    }
  }

  public func wrapWithValueDecoder(_ expr: String) -> String {
    switch swift {
    case .value:
      return expr

    default:
      return "(/Value.\(swift.rawValue)).extract(from: \(expr))"
    }
  }
}
