// Copyright © 2022 foxacid7cd. All rights reserved.

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

    if isSuccess {
      elements += [payload, nil]
    } else {
      elements += [nil, payload]
    }

    return elements
  }
}
