//
//  MessagePackValue+JSON.swift
//  Library
//
//  Created by Yevhenii Matviienko on 14.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import MessagePack

public extension MessagePackValue {
  func makeJSON() throws -> Any {
    switch self {
    case let .array(array):
      return try array.map { try $0.makeJSON() }

    case let .map(map):
      var dictionary = [String: Any]()
      for (key, value) in map {
        guard let key = key.stringValue else {
          throw "dictionary key is expected to be a string in JSON -> \(key)".fail()
        }
        dictionary[key] = try value.makeJSON()
      }
      return dictionary

    case let .bool(value):
      return value

    case let .double(value):
      return value

    case let .float(value):
      return value

    case let .string(value):
      return value

    case let .int(value):
      return value

    case let .uint(value):
      return UInt(value)

    case .extended, .binary, .nil:
      throw "unsupported value type -> \(self)".fail()
    }
  }
}
