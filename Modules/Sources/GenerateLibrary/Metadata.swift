// SPDX-License-Identifier: MIT

import CasePaths
import Foundation
import MessagePack
import SwiftSyntax
import SwiftSyntaxBuilder
import Tagged

public struct Metadata: Sendable {
  public init(functions: [Function], uiEvents: [UIEvent], types: [Type], uiOptions: [String]) {
    self.functions = functions
    self.uiEvents = uiEvents
    self.types = types
    self.uiOptions = uiOptions
  }

  public init?(_ value: Value) {
    guard let dictionary = (/Value.dictionary).extract(from: value) else {
      return nil
    }

    let types: [Type]
    if let rawTypes = dictionary["types"].flatMap(/Value.dictionary) {
      types = rawTypes
        .compactMap { name, rawType in
          guard
            let name = (/Value.string).extract(from: name),
            let rawType = (/Value.dictionary).extract(from: rawType),
            let rawID = rawType["id"].flatMap(/Value.integer),
            let prefix = rawType["prefix"].flatMap(/Value.string)
          else {
            return nil
          }

          return .init(id: .init(rawID), name: name, prefix: prefix)
        }
        .sorted(by: { $0.id < $1.id })
    } else {
      types = []
    }
    self.types = types

    if let functionsValue = dictionary["functions"].flatMap(/Value.array) {
      functions = functionsValue.compactMap { functionValue -> Function? in
        guard let dictionary = (/Value.dictionary).extract(from: functionValue) else {
          return nil
        }

        guard
          let parameterValues = dictionary["parameters"].flatMap(/Value.array),
          let name = dictionary["name"].flatMap(/Value.string),
          let returnType = dictionary["return_type"]
            .flatMap(/Value.string)
            .map({ ValueType(rawValue: $0) }),
          let method = dictionary["method"].flatMap(/Value.boolean),
          let since = dictionary["since"].flatMap(/Value.integer)
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
          deprecatedSince: dictionary["deprecated_since"].flatMap(/Value.integer)
        )
      }
    } else {
      functions = []
    }

    if let rawUIEvents = dictionary["ui_events"].flatMap(/Value.array) {
      uiEvents = rawUIEvents.compactMap { rawUIEvent -> UIEvent? in
        guard
          let rawUIEvent = (/Value.dictionary).extract(from: rawUIEvent),
          let rawParameters = rawUIEvent["parameters"].flatMap(/Value.array),
          let name = rawUIEvent["name"].flatMap(/Value.string)
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

    if let rawUIOptions = dictionary["ui_options"].flatMap(/Value.array) {
      uiOptions = rawUIOptions
        .compactMap((/Value.string).extract(from:))

    } else {
      uiOptions = []
    }
  }

  public struct Function: Sendable {
    public init(
      name: String,
      parameters: [Parameter],
      returnType: ValueType,
      method: Bool,
      since: Int,
      deprecatedSince: Int? = nil
    ) {
      self.name = name
      self.parameters = parameters
      self.returnType = returnType
      self.method = method
      self.since = since
      self.deprecatedSince = deprecatedSince
    }

    public var name: String
    public var parameters: [Parameter]
    public var returnType: ValueType
    public var method: Bool
    public var since: Int
    public var deprecatedSince: Int?
  }

  public struct Parameter: Sendable {
    public init(name: String, type: ValueType) {
      self.name = name
      self.type = type
    }

    public var name: String
    public var type: ValueType

    public init?(_ value: Value, types: [Metadata.`Type`]) {
      guard
        let arrayValue = (/Value.array).extract(from: value), arrayValue.count == 2,
        let rawType = (/Value.string).extract(from: arrayValue[0]),
        var name = (/Value.string).extract(from: arrayValue[1])
      else {
        return nil
      }

      var custom: ValueType.Custom?
      if name == "grid", rawType == "Integer" {
        name = "gridID"
        custom = .init(
          signature: "Grid.ID",
          valueEncoder: (".integer(", ".rawValue)"),
          valueDecoder: ("(/Value.integer).extract(from: ", ").map(Grid.ID.init(rawValue:))")
        )

      } else if let type = types.first(where: { $0.name == rawType }) {
        name = type.name.prefix(1).lowercased() + type.name.dropFirst(1) + "ID"

        custom = .init(
          signature: "\(type.name).ID",
          valueEncoder: (".ext(type: References.\(type.name).type, data: ", ".data)"),
          valueDecoder: (
            "(/Value.ext).extract(from:",
            ").flatMap(References.\(type.name).init(type:data:))"
          )
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
  }

  public struct UIEvent: Sendable {
    public init(name: String, parameters: [Parameter]) {
      self.name = name
      self.parameters = parameters
    }

    public var name: String
    public var parameters: [Parameter]
  }

  public struct `Type`: Sendable {
    public init(id: ID, name: String, prefix: String) {
      self.id = id
      self.name = name
      self.prefix = prefix
    }

    public typealias ID = Tagged<Type, Int>

    public var id: ID
    public var name: String
    public var prefix: String
  }

  public var functions: [Function]
  public var uiEvents: [UIEvent]
  public var types: [Type]
  public var uiOptions: [String]
}

private extension Metadata.Parameter {}
