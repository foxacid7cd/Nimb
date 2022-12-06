// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation

public typealias MessageValue = Any?

public extension MessageValue {
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
  
  var assumingArray: [MessageValue]? {
    guard let arrayValue = self as? [MessageValue] else {
      return nil
    }
    
    return arrayValue
  }
}


public typealias MessageMapValue = [(key: MessageValue, value: MessageValue)]

extension MessageMapValue: ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral elements: (MessageValue, MessageValue)...) {
    self = elements
  }
}

public typealias MessageExtValue = (type: Int8, data: Data)
