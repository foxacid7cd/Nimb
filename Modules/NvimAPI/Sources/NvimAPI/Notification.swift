// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation

public struct Notification {
  public init(method: String, parameters: [Value]) {
    self.method = method
    self.parameters = parameters
  }

  public var method: String
  public var parameters: [Value]

  public var encoded: Value {
    .init([
      2,
      method,
      parameters,
    ])
  }
}
