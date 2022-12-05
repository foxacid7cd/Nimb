// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation

public typealias MessageValue = Any?

public typealias MessageMapValue = [(key: MessageValue, value: MessageValue)]

extension MessageMapValue: ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral elements: (MessageValue, MessageValue)...) {
    self = elements
  }
}

public typealias MessageExtValue = (type: Int8, data: Data)
