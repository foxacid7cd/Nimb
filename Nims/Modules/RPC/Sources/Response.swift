//
//  Response.swift
//  MessagePack
//
//  Created by Yevhenii Matviienko on 28.11.2022.
//

import Foundation
import Tagged

public struct Response {
  public init(id: ID, isSuccess: Bool, payload: Any?) {
    self.id = id
    self.isSuccess = isSuccess
    self.payload = payload
  }

  public typealias ID = Request.ID

  public let id: ID
  public var isSuccess: Bool
  public var payload: Value

  public func makeValue() -> Value {
    var elements: [Value] = [1, id.rawValue]

    if self.isSuccess {
      elements += [self.payload, nil]

    } else {
      elements += [nil, self.payload]
    }

    return elements
  }
}
