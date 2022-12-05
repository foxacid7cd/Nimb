// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation

public actor API {
  public init(rpc: RPCProtocol) {
    self.rpc = rpc
  }

  public init(channel: RPCChannel) {
    self.init(rpc: RPC(channel: channel))
  }

  let rpc: RPCProtocol
}
