// SPDX-License-Identifier: MIT

import CasePaths
import Foundation
import Library
import MessagePack
import SwiftSyntax
import SwiftSyntaxBuilder

@PublicInit
public struct Metadata: @unchecked Sendable {
  public init(_ value: Value) throws {
    guard
      let dictionary = value.dictionary,
      let rawTypes = dictionary["types"].flatMap(\.dictionary),
      let rawErrorTypes = dictionary["error_types"].flatMap(\.dictionary),
      let rawFunctions = dictionary["functions"].flatMap(\.array),
      let rawUIEvents = dictionary["ui_events"].flatMap(\.array),
      let rawUIOptions = dictionary["ui_options"].flatMap(\.array)
    else {
      throw Failure("Invalid Metadata raw value format", value)
    }

    let types = try rawTypes
      .map { name, rawType -> Metadata.`Type` in
        guard
          case let .string(name) = name,
          case let .dictionary(rawType) = rawType,
          case let .integer(rawID) = rawType["id"],
          case let .string(prefix) = rawType["prefix"]
        else {
          throw Failure("Could not parse type", name, rawType)
        }
        return .init(id: .init(rawID), name: name, prefix: prefix)
      }
      .sorted(by: { $0.id < $1.id })

    try self.init(
      types: types,

      errorTypes: rawErrorTypes
        .map { key, value -> Metadata.ErrorType in
          guard
            let name = key.string, let dict = value.dictionary,
            let id = dict["id"]?.integer
          else {
            throw Failure("Could not parse error_type", key, value)
          }
          return .init(id: id, name: name)
        }
        .sorted(by: { $0.id < $1.id }),

      functions: rawFunctions.map { rawFunction -> Metadata.Function in
        guard case let .dictionary(dictionary) = rawFunction else {
          throw Failure("Functions array value is not dictionary", rawFunction)
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
          throw Failure("Could not parse function", dictionary)
        }

        return .init(
          name: name,
          parameters: parameterValues
            .compactMap { Metadata.Parameter($0, types: types) },
          returnType: returnType,
          method: method,
          since: since,
          deprecatedSince: dictionary["deprecated_since"].flatMap(\.integer)
        )
      },

      uiEvents: rawUIEvents.map { rawUIEvent -> Metadata.UIEvent in
        guard
          case let .dictionary(rawUIEvent) = rawUIEvent,
          case let .array(rawParameters) = rawUIEvent["parameters"],
          case let .string(name) = rawUIEvent["name"]
        else {
          throw Failure("Could not parse ui_event", rawUIEvent)
        }

        return .init(
          name: name,
          parameters: rawParameters
            .compactMap { Metadata.Parameter($0, types: types) }
        )
      },

      uiOptions: rawUIOptions
        .map {
          guard let string = $0.string else {
            throw Failure("ui_options array value is not string")
          }
          return string
        }
    )
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
          valueEncoder: (
            ".ext(type: References.\(type.name).type, data: ",
            ".data)"
          ),
          valueDecoder: { expr, name in
            var capitalizedName = name.first?.uppercased() ?? ""
            capitalizedName += name.dropFirst()
            let rawTypeIdentifier = "raw\(capitalizedName)Type"
            let rawDataIdentifier = "raw\(capitalizedName)Data"
            return """
            case let .ext(\(rawTypeIdentifier), \(rawDataIdentifier)) = \(
              expr
            ),
            let \(name) = References.\(
              type
                .name
            )(type: \(rawTypeIdentifier), data: \(rawDataIdentifier))
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

  @PublicInit
  public struct ErrorType: Sendable {
    public var id: Int
    public var name: String
  }

  public var types: [Type]
  public var errorTypes: [ErrorType]
  public var functions: [Function]
  public var uiEvents: [UIEvent]
  public var uiOptions: [String]
}
