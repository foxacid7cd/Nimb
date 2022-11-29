//
//  RPCNotification.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 28.11.2022.
//

import Foundation

public struct RPCNotification: MessageValueEncodable {
  public var method: String
  public var parameters: [Any?]
  
  public init(method: String, parameters: [Any?]) {
    self.method = method
    self.parameters = parameters
  }
  
  public var messageValueEncoded: Any? {
    [2, method, parameters]
  }
}
