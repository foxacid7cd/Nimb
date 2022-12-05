// Copyright © 2022 foxacid7cd. All rights reserved.

import MessagePack

public actor API {
  public init(rpc: RPCProtocol) {
    self.rpc = rpc
  }

  func call<Success>(
    method: String,
    withParameters parameters: [Value],
    assumingSuccessType successType: Success.Type
  ) async throws -> Result<Success, RemoteError> {
    try await rpc.call(method: method, withParameters: parameters)
      .map { success in
        guard let success = success as? Success else {
          preconditionFailure("Assumed success type does not match real success type")
        }

        return success
      }
  }

  private let rpc: RPCProtocol
}
