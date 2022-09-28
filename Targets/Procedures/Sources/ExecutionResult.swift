//
//  ExecutionResult.swift
//  
//
//  Created by Yevhenii Matviienko on 28.09.2022.
//

import MessagePack

public struct ExecutionResult {
  public var isSuccess: Bool
  public var payload: MessagePackValue
  
  public init(isSuccess: Bool, payload: MessagePackValue) {
    self.isSuccess = isSuccess
    self.payload = payload
  }
}
