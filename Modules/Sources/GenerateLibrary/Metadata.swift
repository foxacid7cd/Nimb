// SPDX-License-Identifier: MIT

import CasePaths
import Foundation
import Library
import MessagePack
import SwiftSyntax
import SwiftSyntaxBuilder

@PublicInit
public struct Metadata: Sendable {
  public init?(_ value: Value) {
    guard case let .dictionary(dictionary) = value else {
      return nil
    }

    let types: [Type] = if let rawTypes = dictionary["types"].flatMap(\.dictionary) {
      rawTypes
        .compactMap { name, rawType in
          guard
            case let .string(name) = name,
            case let .dictionary(rawType) = rawType,
            case let .integer(rawID) = rawType["id"],
            case let .string(prefix) = rawType["prefix"]
          else {
            return nil
          }

          return .init(id: .init(rawID), name: name, prefix: prefix)
        }
        .sorted(by: { $0.id < $1.id })
    } else {
      []
    }
    self.types = types

    if let functionsValue = dictionary["functions"].flatMap(\.array) {
      functions = functionsValue.compactMap { functionValue -> Function? in
        guard case let .dictionary(dictionary) = functionValue else {
          return nil
        }

        guard
          let parameterValues = dictionary["parameters"].flatMap(\.array),
          let name = dictionary["name"].flatMap(\.string),
          let returnType = dictionary["return_type"]
            .flatMap(\.string)
            .map({ ValueType(rawValue: $0) }),
          let method = dictionary["method"].flatMap(\.boolean),
          let since = dictionary["since"].flatMap(\.integer)
        else {
          return nil
        }

        return .init(
          name: name,
          parameters: parameterValues
            .compactMap { Parameter($0, types: types) },
          returnType: returnType,
          method: method,
          since: since,
          deprecatedSince: dictionary["deprecated_since"].flatMap(\.integer)
        )
      }
    } else {
      functions = []
    }

    if let rawUIEvents = dictionary["ui_events"].flatMap(\.array) {
      uiEvents = rawUIEvents.compactMap { rawUIEvent -> UIEvent? in
        guard
          case let .dictionary(rawUIEvent) = rawUIEvent,
          case let .array(rawParameters) = rawUIEvent["parameters"],
          case let .string(name) = rawUIEvent["name"]
        else {
          return nil
        }

        return .init(
          name: name,
          parameters: rawParameters
            .compactMap { Parameter($0, types: types) }
        )
      }
    } else {
      uiEvents = []
    }

    if let rawUIOptions = dictionary["ui_options"].flatMap(\.array) {
      uiOptions = rawUIOptions
        .compactMap { $0[case: \.string] }

    } else {
      uiOptions = []
    }
  }

  @PublicInit
  public struct Function: Sendable {
    public var name: String
    public var parameters: [Parameter]
    public var returnType: ValueType
    public var method: Bool
    public var since: Int
    public var deprecatedSince: Int?

    public var deprecationAttributeIfNeeded: String {
      if let deprecatedSince {
        "@available(*, deprecated, message: \"since version \(deprecatedSince)\")"
      } else {
        ""
      }
    }
  }

  @PublicInit
  public struct Parameter: Sendable {
    public init?(_ value: Value, types: [Metadata.`Type`]) {
      guard
        case let .array(arrayValue) = value,
        arrayValue.count == 2,
        case let .string(rawType) = arrayValue[0],
        case var .string(name) = arrayValue[1]
      else {
        return nil
      }

      var custom: ValueType.Custom?
      if let type = types.first(where: { $0.name == rawType }) {
        name = type.name.prefix(1).lowercased() + type.name.dropFirst(1) + "ID"

        custom = .init(
          signature: "\(type.name).ID",
          valueEncoder: (".ext(type: References.\(type.name).type, data: ", ".data)"),
          valueDecoder: { expr, name in
            var capitalizedName = name.first?.uppercased() ?? ""
            capitalizedName += name.dropFirst()
            let rawTypeIdentifier = "raw\(capitalizedName)Type"
            let rawDataIdentifier = "raw\(capitalizedName)Data"
            return """
              case let .ext(\(rawTypeIdentifier), \(rawDataIdentifier)) = \(expr),
              let \(name) = References.\(type.name)(type: \(rawTypeIdentifier), data: \(rawDataIdentifier))
            """
          }
        )
      }

      self.init(
        name: name,
        type: .init(
          rawValue: rawType,
          custom: custom
        )
      )
    }

    public var name: String
    public var type: ValueType
  }

  @PublicInit
  public struct UIEvent: Sendable {
    public var name: String
    public var parameters: [Parameter]
  }

  @PublicInit
  public struct `Type`: Sendable {
    public var id: Int
    public var name: String
    public var prefix: String
  }

  public var functions: [Function]
  public var uiEvents: [UIEvent]
  public var types: [Type]
  public var uiOptions: [String]
}
