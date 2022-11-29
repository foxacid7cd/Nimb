//
//  RPCResponse.swift
//  MessagePack
//
//  Created by Yevhenii Matviienko on 28.11.2022.
//

import Foundation

public struct RPCResponse: MessageValueEncodable {
  var id: Int
  var isSuccess: Bool
  var payload: Any?
  
  public init(id: Int, isSuccess: Bool, payload: Any?) {
    self.id = id
    self.isSuccess = isSuccess
    self.payload = payload
  }
  
  public var messageValueEncoded: Any? {
    var elements: [Any?] = [1, id]
    
    if isSuccess {
      elements += [payload, nil]
      
    } else {
      elements += [nil, payload]
    }
    
    return elements
  }
}

