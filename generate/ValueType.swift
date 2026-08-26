// SPDX-License-Identifier: MIT

import Foundation
import NimbCore

public struct ValueType: Sendable {
  public struct Custom: Sendable {
    public var signature: String
    public var valueEncoder: (prefix: String, suffix: String)
    public var valueDecoder: @Sendable (_ expr: String, _ name: String)
      -> String
    /// Expressions for using this type as an array element, where a pattern
    /// matching condition cannot be spliced in.
    public var elementEncoder: String
    public var elementDecoder: String
  }

  public indirect enum SwiftType {
    case unsignedInteger
    case integer
    case float
    case string
    case boolean
    case dictionary
    case array
    case arrayOf(ValueType)
    case binary
    case custom(Custom)
    case void
    case value

    /// Replaces `.value`, the only case path taken on this type.
    public var isValue: Bool {
      if case .value = self {
        true
      } else {
        false
      }
    }

    public var isVoid: Bool {
      if case .void = self {
        true
      } else {
        false
      }
    }

    public var signature: String {
      switch self {
      case .unsignedInteger: "UInt"
      case .integer: "Int"
      case .float: "Double"
      case .string: "String"
      case .boolean: "Bool"
      case .dictionary: "[Value: Value]"
      case .array: "[Value]"
      case let .arrayOf(element): "[\(element.swift.signature)]"
      case .binary: "Data"
      case let .custom(custom): custom.signature
      case .void: "Void"
      case .value: "Value"
      }
    }

    /// Turns one element of this type into a Value, given `$0`.
    var elementEncoder: String {
      switch self {
      case .unsignedInteger: ".unsignedInteger($0)"
      case .integer: ".integer($0)"
      case .float: ".float($0)"
      case .string: ".string($0)"
      case .boolean: ".boolean($0)"
      case .dictionary: ".dictionary($0)"
      case .array: ".array($0)"
      case let .arrayOf(element): ".array($0.map { \(element.swift.elementEncoder) })"
      case .binary: ".binary($0)"
      case let .custom(custom): custom.elementEncoder
      case .void, .value: "$0"
      }
    }

    /// Recovers one element of this type from a Value, given `$0`, or nil.
    var elementDecoder: String {
      switch self {
      case .unsignedInteger: "$0.unsignedInteger"
      case .integer: "$0.integer"
      case .float: "$0.float"
      case .string: "$0.string"
      case .boolean: "$0.boolean"
      case .dictionary: "$0.dictionary"
      case .array: "$0.array"
      case let .arrayOf(element):
        "Value.decodeArray($0, { \(element.swift.elementDecoder) })"
      case .binary: "$0.binary"
      case let .custom(custom): custom.elementDecoder
      case .void, .value: "$0"
      }
    }
  }

  public var rawValue: String
  public var custom: Custom? = nil

  /// The element of `ArrayOf(T)` / `ArrayOf(T, N)`, if this is one.
  ///
  /// The fixed length some of them carry is dropped: expressing it would mean
  /// a tuple, which cannot be a stored property of a `@PublicInit` struct
  /// without losing Hashable, and the count is already implied by the API.
  var arrayElementRawValue: String? {
    guard rawValue.hasPrefix("ArrayOf(") , rawValue.hasSuffix(")") else {
      return nil
    }
    let inner = rawValue.dropFirst("ArrayOf(".count).dropLast()
    return inner.split(separator: ",").first.map {
      $0.trimmingCharacters(in: .whitespaces)
    }
  }

  public var swift: SwiftType {
    if let custom {
      .custom(custom)

    } else if let element = arrayElementRawValue, element != "Object" {
      // Object elements stay untyped -- `[Value]` already says exactly that.
      .arrayOf(.init(rawValue: element, custom: Self.customForExtType(element)))

    } else if rawValue.starts(with: "Array") {
      .array

      // Neovim renamed this from "Dictionary" to "Dict" for functions while
      // ui_events kept the old spelling, so matching only one of them quietly
      // dropped every dictionary parameter to an untyped Value.
    } else if rawValue == "Dict" || rawValue == "Dictionary" {
      .dictionary

    } else if ["Integer", "LuaRef"].contains(rawValue) {
      .integer

    } else if rawValue == "Float" {
      .float

    } else if rawValue == "String" {
      .string

    } else if rawValue == "Boolean" {
      .boolean

    } else if rawValue == "void" {
      .void

    } else {
      .value
    }
  }

  /// Element types inside an ArrayOf still need the ext handling that a bare
  /// parameter of the same type gets, and the metadata does not repeat it.
  static func customForExtType(_ name: String) -> Custom? {
    guard ["Buffer", "Window", "Tabpage"].contains(name) else {
      return nil
    }
    return .init(
      signature: "References.\(name)",
      valueEncoder: (".ext(type: References.\(name).type, data: ", ".data)"),
      valueDecoder: { expr, bound in
        """
        case let .ext(raw\(bound)Type, raw\(bound)Data) = \(expr),
        let \(bound) = References.\(name)(type: raw\(bound)Type, data: raw\(bound)Data)
        """
      },
      elementEncoder: ".ext(type: References.\(name).type, data: $0.data)",
      elementDecoder: "$0.ext.flatMap { References.\(name)(type: $0.type, data: $0.data) }",
    )
  }

  public func wrapWithValueEncoder(_ expr: String) -> String {
    switch swift {
    case .unsignedInteger: ".unsignedInteger(\(expr))"
    case .integer: ".integer(\(expr))"
    case .float: ".float(\(expr))"
    case .string: ".string(\(expr))"
    case .boolean: ".boolean(\(expr))"
    case .dictionary: ".dictionary(\(expr))"
    case .array: ".array(\(expr))"
    case let .arrayOf(element):
      ".array(\(expr).map { \(element.swift.elementEncoder) })"
    case .binary: ".binary(\(expr))"
    case let .custom(custom):
      custom.valueEncoder.prefix + expr + custom.valueEncoder.suffix
    case .void, .value: expr
    }
  }

  public func wrapWithValueDecoder(_ expr: String, name: String) -> String {
    switch swift {
    case .unsignedInteger: "case let .unsignedInteger(\(name)) = \(expr)"
    case .integer: "case let .integer(\(name)) = \(expr)"
    case .float: "case let .float(\(name)) = \(expr)"
    case .string: "case let .string(\(name)) = \(expr)"
    case .boolean: "case let .boolean(\(name)) = \(expr)"
    case .dictionary: "case let .dictionary(\(name)) = \(expr)"
    case .array: "case let .array(\(name)) = \(expr)"
    case let .arrayOf(element):
      "let \(name) = Value.decodeArray(\(expr), { \(element.swift.elementDecoder) })"
    case .binary: "case let .binary(\(name)) = \(expr)"
    case let .custom(custom): custom.valueDecoder(expr, name)
    case .void, .value: expr
    }
  }
}
