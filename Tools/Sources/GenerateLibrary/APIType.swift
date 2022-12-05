// Copyright © 2022 foxacid7cd. All rights reserved.

private let MapTypes: Set = ["Object", "Dictionary"]
private let IntegerTypes: Set = ["Buffer", "Integer", "LuaRef", "Tabpage", "Window"]

enum APIType {
  case integer
  case float
  case string
  case boolean
  case map
  case array
  case value

  init(_ rawValue: String) {
    if rawValue.starts(with: "Array") {
      self = .array

    } else if MapTypes.contains(rawValue) {
      self = .map

    } else if IntegerTypes.contains(rawValue) {
      self = .integer

    } else if rawValue == "Float" {
      self = .float

    } else if rawValue == "String" {
      self = .string

    } else if rawValue == "Boolean" {
      self = .boolean

    } else {
      self = .value
    }
  }

  var inSignature: String {
    switch self {
    case .integer:
      return "Int"

    case .float:
      return "Double"

    case .string:
      return "String"

    case .boolean:
      return "Bool"

    case .map:
      return "MessageMapValue"

    case .array:
      return "[MessageValue]"

    case .value:
      return "MessageValue"
    }
  }
}
