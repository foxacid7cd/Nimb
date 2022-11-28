//
//  RPCNotification.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 28.11.2022.
//

import Foundation

public struct RPCNotification: MessageValue {
  var method: String
  var parameters: [MessageValue]
  
  public init(method: String, parameters: [MessageValue]) {
    self.method = method
    self.parameters = parameters
  }
  
  public func pack(to packer: MessagePacker) {
    MessageArrayValue([
      MessageInt64Value(2),
      MessageStringValue(method),
      MessageArrayValue(parameters)
    ])
    .pack(to: packer)
  }
}
