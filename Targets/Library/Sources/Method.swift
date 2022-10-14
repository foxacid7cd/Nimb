//
//  Method.swift
//  Library
//
//  Created by Yevhenii Matviienko on 14.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation
import MessagePack

public struct Method {
  public var name: String
  public var parameters: [MessagePackValue]

  public init(name: String, parameters: [MessagePackValue]) {
    self.name = name
    self.parameters = parameters
  }

  public init(messagePackValue: MessagePackValue) throws {
    guard var array = messagePackValue.arrayValue else {
      throw "Is not an array."
    }

    guard !array.isEmpty else {
      throw "Is empty."
    }

    let rawName = array.removeFirst()
    guard let name = rawName.stringValue else {
      throw "Invalid first element type, expected String, got \(rawName)."
    }

    self.init(name: name, parameters: array)
  }
}
