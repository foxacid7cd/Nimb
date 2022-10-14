//
//  MessageNotification.swift
//  Library
//
//  Created by Yevhenii Matviienko on 14.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import MessagePack

public struct MessageNotification {
  public var method: String
  public var parametersArray: [[MessagePackValue]]

  public init(method: String, parametersArray: [[MessagePackValue]]) {
    self.method = method
    self.parametersArray = parametersArray
  }
}
