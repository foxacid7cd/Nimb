//
//  RPCResponse.swift
//  MessagePack
//
//  Created by Yevhenii Matviienko on 28.11.2022.
//

import Foundation

public struct RPCResponse: MessageValue {
  var id: Int
  var isSuccess: Bool
  var payload: MessageValue
  
  public init(id: Int, isSuccess: Bool, payload: MessageValue) {
    self.id = id
    self.isSuccess = isSuccess
    self.payload = payload
  }
  
  public func pack(to packer: MessagePacker) {
    var elements: [MessageValue] = [MessageIntValue(1), MessageIntValue(id)]
    
    if isSuccess {
      elements += [payload, MessageNilValue()]
      
    } else {
      elements += [MessageNilValue(), payload]
    }
    
    MessageArrayValue(elements)
      .pack(to: packer)
  }
}

