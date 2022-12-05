// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation

public actor API {
  public init(rpc: RPCProtocol) {
    self.rpc = rpc
  }

  let rpc: RPCProtocol
}
