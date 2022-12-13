// Copyright © 2022 foxacid7cd. All rights reserved.

import CasePaths
import Foundation
import MessagePack
import SwiftSyntax
import SwiftSyntaxBuilder

public struct Metadata: Hashable {
  public struct Function: Hashable {
    public var name: String
    public var parameters: [Parameter]
    public var returnType: ValueType
    public var method: Bool
    public var since: Int
    public var deprecatedSince: Int?
  }

  public struct Parameter: Hashable {
    public var name: String
    public var type: ValueType
  }

  public struct UIEvent: Hashable {
    public var name: String
    public var parameters: [Parameter]
  }

  public var functions: [Function]
  public var uiEvents: [UIEvent]
}

public extension Metadata {
  init?(_ value: Value) {
    guard let dictionary = value[/Value.dictionary] else {
      return nil
    }

    if let functionsValue = dictionary["functions"]?[/Value.array] {
      functions = functionsValue
        .compactMap { functionValue -> Function? in
          guard let dictionary = functionValue[/Value.dictionary] else {
            return nil
          }

          guard
            let parameterValues = dictionary["parameters"]?[/Value.array],
            let name = dictionary["name"]?[/Value.string],
            let returnType = dictionary["return_type"]?[/Value.string]
              .map(ValueType.init(metadataString:)),
            let method = dictionary["method"]?[/Value.boolean],
            let since = dictionary["since"]?[/Value.integer]
          else {
            return nil
          }

          return .init(
            name: name,
            parameters: parameterValues
              .compactMap { Parameter($0) },
            returnType: returnType,
            method: method,
            since: since,
            deprecatedSince: dictionary["deprecated_since"]?[/Value.integer]
          )
        }
    } else {
      functions = []
    }

    if let uiEventsValue = dictionary["ui_events"]?[/Value.array] {
      uiEvents = uiEventsValue
        .compactMap { uiEventValue -> UIEvent? in
          guard let dictionary = uiEventValue[/Value.dictionary] else {
            return nil
          }

          guard
            let parameterValues = dictionary["parameters"]?[/Value.array],
            let name = dictionary["name"]?[/Value.string]
          else {
            return nil
          }

          return .init(
            name: name,
            parameters: parameterValues
              .compactMap { Parameter($0) }
          )
        }
    } else {
      uiEvents = []
    }
  }
}

private extension Metadata.Parameter {
  init?(_ value: Value) {
    guard
      let arrayValue = value[/Value.array],
      arrayValue.count == 2,
      let type = arrayValue[0][/Value.string],
      let name = arrayValue[1][/Value.string]
    else {
      return nil
    }

    self.init(
      name: name,
      type: .init(metadataString: type)
    )
  }
}
