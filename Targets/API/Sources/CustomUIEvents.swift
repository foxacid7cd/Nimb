//
//  CustomUIEvents.swift
//  Library
//
//  Created by Yevhenii Matviienko on 14.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Library
import MessagePack

public extension UIEvents {
  typealias OptionSet = [String: MessagePackValue]
}

public extension UIEvents.OptionSet {
  static func fromUIEvent(parameters: [MessagePackValue]) throws -> Self {
    try parameters.reduce(into: Self()) { result, parameter in
      guard let array = parameter.arrayValue, array.count == 2, let name = array[0].stringValue else {
        throw "Could not parse parameters, parameters: \(parameters)."
      }
      result[name] = array[1]
    }
  }
}
