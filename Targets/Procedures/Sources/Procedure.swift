//
//  Procedure.swift
//  
//
//  Created by Yevhenii Matviienko on 28.09.2022.
//

import MessagePack

public struct Procedure {
  public var method: String
  public var params: [MessagePackValue]
  
  public init(method: String, params: [MessagePackValue]) {
    self.method = method
    self.params = params
  }
}
