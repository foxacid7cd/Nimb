//
//  Notification.swift
//  Procedures
//
//  Created by Yevhenii Matviienko on 13.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import MessagePack

public struct Notification {
  public var method: String
  public var params: [MessagePackValue]

  public init(method: String, params: [MessagePackValue]) {
    self.method = method
    self.params = params
  }
}
