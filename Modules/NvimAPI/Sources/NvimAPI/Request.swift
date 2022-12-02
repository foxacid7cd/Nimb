//
//  Request.swift
//  MessagePack
//
//  Created by Yevhenii Matviienko on 28.11.2022.
//

import Foundation
import Tagged

public struct Request: Identifiable {
  public init(id: ID, method: String, parameters: [Value]) {
    self.id = id
    self.method = method
    self.parameters = parameters
  }

  public typealias ID = Tagged<Request, Int>

  public let id: ID
  public var method: String
  public var parameters: [Value]

  public func makeValue() -> Value {
    .init([
      0,
      id.rawValue,
      method,
      parameters,
    ])
  }
}
