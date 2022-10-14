//
//  Method.swift
//  Library
//
//  Created by Yevhenii Matviienko on 14.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import MessagePack

public struct Method {
  public var name: String
  public var parameters: [MessagePackValue]

  public init(name: String, parameters: [MessagePackValue]) {
    self.name = name
    self.parameters = parameters
  }
}
