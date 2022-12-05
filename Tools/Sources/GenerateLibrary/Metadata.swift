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

  public var functions: [Function]
}

public extension Metadata {
  init?(value: MessageValue) {
    guard let dictionary = value.assumingDictionary else {
      return nil
    }
    
    guard let functionsArrayValue = dictionary["functions"] as? [MessageValue] else {
      return nil
    }
    
    self.functions = functionsArrayValue
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
    }

  static func generateFiles(dataBatches: AsyncStream<Data>) async throws -> [(name: String, content: String)] {
    var accumulator = [MessageValue]()
    
    let unpacker = Unpacker()
    for await data in dataBatches {
      let values = try await unpacker.unpack(data)
      
      accumulator += values
    }
    
    guard
      accumulator.count == 1,
      let apiInfoMap = accumulator[0] as? MessageMapValue,
      let metadata = Metadata(value: apiInfoMap)
    else {
      return []
    }

    return [APIFunctionsFile(metadata: metadata)]
      .map {
        (
          $0.fileName,
          SourceFile(statements: $0.statements)
            .formatted()
            .description
        )
      }
  }
}

private extension MessageValue {
  var assumingDictionary: [String: MessageValue]? {
    guard let mapValue = self as? MessageMapValue else {
      return nil
    }
    
    var accumulator = [String: MessageValue]()
    
    for (key, value) in mapValue {
      guard let key = key as? String else {
        continue
      }
      
      accumulator[key] = value
    }
    
    return accumulator
  }
}
