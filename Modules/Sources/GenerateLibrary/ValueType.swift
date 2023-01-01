// SPDX-License-Identifier: MIT

public struct ValueType: Sendable, Equatable {
  public init(rawValue: String, types: [Metadata.`Type`]) {
    self.rawValue = rawValue
    self.types = types
  }

  public enum SwiftType {
    case integer
    case float
    case string
    case boolean
    case dictionary
    case array
    case binary
    case reference(Metadata.`Type`)
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

      case let .reference(type):
        return "References.\(type.name)"

      case .value:
        return "Value"
      }
    }
  }

  public var rawValue: String
  public var types: [Metadata.`Type`]

  public var swift: SwiftType {
    if rawValue.starts(with: "Array") {
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

    } else if let type = types.first(where: { rawValue == $0.name }) {
      return .reference(type)

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

    case let .reference(type):
      return ".ext(type: References.\(type.name).type, data: \(expr).data)"

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

    case let .reference(type):
      return "(/Value.ext).extract(from: \(expr)).flatMap(References.\(type.name).init)\(forceUnwrapSuffix)"

    case .value:
      return expr
    }
  }
}
