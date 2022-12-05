// Copyright © 2022 foxacid7cd. All rights reserved.

import MessagePack

public actor API {
  public init(rpc: RPCProtocol) {
    self.rpc = rpc
  }

  func call<Success>(
    method: String,
    withParameters parameters: [MessageValue],
    assumingSuccessType successType: Success.Type
  ) async throws -> Result<Success, RemoteError> {
    try await rpc.call(method: method, withParameters: parameters)
      .map { success in
        guard let success = success as? Success else {
          preconditionFailure("Assumed success response type does not match returned response type")
        }
        return success
      }
  }

  private let rpc: RPCProtocol
}
