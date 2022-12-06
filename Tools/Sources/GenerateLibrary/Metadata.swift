// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation
import MessagePack
import SwiftSyntax
import SwiftSyntaxBuilder

public struct Metadata: Hashable {
  public struct Function: Hashable {
    public var name: String
    public var parameters: [Parameter]
    public var returnType: String
    public var method: Bool
    public var since: Int
    public var deprecatedSince: Int?
  }

  public struct Parameter: Hashable {
    public var name: String
    public var type: String
  }

  public struct UIEvent: Hashable {
    public var name: String
    public var parameters: [Parameter]
  }

  public var functions: [Function]
  public var uiEvents: [UIEvent]
}

public extension Metadata {
  init?(value: MessageValue) {
    guard let dictionary = value.assumingDictionary else {
      return nil
    }

    if let functionsValue = dictionary["functions"] as? [MessageValue] {
      functions = functionsValue
        .compactMap { functionValue -> Function? in
          guard let dictionary = functionValue.assumingDictionary else {
            return nil
          }

          guard
            let parameters = dictionary["parameters"] as? [MessageValue],
            let name = dictionary["name"] as? String,
            let returnType = dictionary["return_type"] as? String,
            let method = dictionary["method"] as? Bool,
            let since = dictionary["since"] as? Int
          else {
            return nil
          }

          return .init(
            name: name,
            parameters: parameters
              .compactMap { parameterValue in
                guard let pair = parameterValue as? [String], pair.count == 2 else {
                  return nil
                }
                return Parameter(name: pair[1], type: pair[0])
              },
            returnType: returnType,
            method: method,
            since: since,
            deprecatedSince: dictionary["deprecated_since"] as? Int
          )
        }
    } else {
      functions = []
    }

    if let uiEventsValue = dictionary["ui_events"] as? [MessageValue] {
      uiEvents = uiEventsValue
        .compactMap { uiEventValue -> UIEvent? in
          guard let dictionary = uiEventValue.assumingDictionary else {
            return nil
          }

          guard
            let parameterValues = dictionary["parameters"] as? [MessageValue],
            let name = dictionary["name"] as? String
          else {
            return nil
          }

          return .init(
            name: name,
            parameters: parameterValues
              .compactMap { Parameter(value: $0) }
          )
        }
    } else {
      uiEvents = []
    }
  }
}

private extension Metadata.Parameter {
  init?(value: MessageValue) {
    guard
      let pair = value as? [String],
      pair.count == 2
    else {
      return nil
    }

    self.init(
      name: pair[1],
      type: pair[0]
    )
  }
}
