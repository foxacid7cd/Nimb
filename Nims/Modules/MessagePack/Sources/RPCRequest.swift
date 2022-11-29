//
//  RPCRequest.swift
//  MessagePack
//
//  Created by Yevhenii Matviienko on 28.11.2022.
//

import Foundation

public struct RPCRequest: MessageValue {
  var id: Int
  var method: String
  var parameters: [MessageValue]
  
  public init(id: Int, method: String, parameters: [MessageValue]) {
    self.id = id
    self.method = method
    self.parameters = parameters
  }
  
  public func pack(to packer: MessagePacker) {
    MessageArrayValue([
      MessageIntValue(0),
      MessageIntValue(id),
      MessageStringValue(method),
      MessageArrayValue(parameters)
    ])
    .pack(to: packer)
  }
}
