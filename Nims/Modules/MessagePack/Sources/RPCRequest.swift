//
//  RPCRequest.swift
//  MessagePack
//
//  Created by Yevhenii Matviienko on 28.11.2022.
//

import Foundation

public struct RPCRequest: MessageValue {
  var id: UInt32
  var method: String
  var parameters: [MessageValue]
  
  public init(id: UInt32, method: String, parameters: [MessageValue]) {
    self.id = id
    self.method = method
    self.parameters = parameters
  }
  
  public func pack(to packer: MessagePacker) {
    MessageArrayValue([
      MessageInt64Value(0),
      MessageUInt32Value(id),
      MessageStringValue(method),
      MessageArrayValue(parameters)
    ])
    .pack(to: packer)
  }
}
