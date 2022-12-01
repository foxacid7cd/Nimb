//
//  RPCNotification.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 28.11.2022.
//

import Foundation

public struct Notification {
  public init(method: String, parameters: [Value]) {
    self.method = method
    self.parameters = parameters
  }

  public var method: String
  public var parameters: [Value]

  public var encoded: Value {
    .init([
      2,
      self.method,
      self.parameters,
    ])
  }
}
