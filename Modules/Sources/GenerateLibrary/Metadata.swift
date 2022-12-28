// SPDX-License-Identifier: MIT

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
  init?(
    _ value: Value
  ) {
    guard let dictionary = (/Value.dictionary).extract(from: value) else { return nil }

    if let functionsValue = dictionary["functions"].flatMap(/Value.array) {
      functions = functionsValue.compactMap { functionValue -> Function? in
        guard let dictionary = (/Value.dictionary).extract(from: functionValue) else { return nil }

        guard
          let parameterValues = dictionary["parameters"].flatMap(/Value.array),
          let name = dictionary["name"].flatMap(/Value.string),
          let returnType = dictionary["return_type"].flatMap(/Value.string)
            .map(ValueType.init(metadataString:)),
          let method = dictionary["method"].flatMap(/Value.boolean),
          let since = dictionary["since"].flatMap(/Value.integer)
        else { return nil }

        return .init(
          name: name,
          parameters: parameterValues.compactMap { Parameter($0) },
          returnType: returnType,
          method: method,
          since: since,
          deprecatedSince: dictionary["deprecated_since"].flatMap(/Value.integer)
        )
      }
    } else {
      functions = []
    }

    if let uiEventsValue = dictionary["ui_events"].flatMap(/Value.array) {
      uiEvents = uiEventsValue.compactMap { uiEventValue -> UIEvent? in
        guard let dictionary = (/Value.dictionary).extract(from: uiEventValue) else { return nil }

        guard
          let parameterValues = dictionary["parameters"].flatMap(/Value.array),
          let name = dictionary["name"].flatMap(/Value.string)
        else { return nil }

        return .init(name: name, parameters: parameterValues.compactMap { Parameter($0) })
      }
    } else {
      uiEvents = []
    }
  }
}

private extension Metadata.Parameter {
  init?(
    _ value: Value
  ) {
    guard
      let arrayValue = (/Value.array).extract(from: value), arrayValue.count == 2,
      let type = (/Value.string).extract(from: arrayValue[0]),
      let name = (/Value.string).extract(from: arrayValue[1])
    else { return nil }

    self.init(name: name, type: .init(metadataString: type))
  }
}
