//
//  Request.swift
//  Library
//
//  Created by Yevhenii Matviienko on 16.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

public struct Request {
  public init(method: String, parameters: [Value]) {
    self.method = method
    self.parameters = parameters
  }

  public var method: String
  public var parameters: [Value]
}
