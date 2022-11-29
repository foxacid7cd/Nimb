//
//  RPCRequest.swift
//  MessagePack
//
//  Created by Yevhenii Matviienko on 28.11.2022.
//

import Foundation

public struct RPCRequest: MessageValueEncodable {
  public init(id: Int, method: String, parameters: [MessageValue]) {
    self.id = id
    self.method = method
    self.parameters = parameters
  }

  public var messageValueEncoded: Any? {
    [0, self.id, self.method, self.parameters]
  }

  var id: Int
  var method: String
  var parameters: [MessageValue]
}
