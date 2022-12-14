// Copyright © 2022 foxacid7cd. All rights reserved.

import AsyncAlgorithms
import CasePaths
import MessagePack

public actor API {
  public init(_ channel: some Channel) {
    let rpc = RPC(channel)
    self.rpc = rpc

    let (sendUIEventBatch, uiEventBatches) = AsyncChannel<UIEventBatch>.pipe()
    self.uiEventBatches = uiEventBatches

    task = Task {
      for try await notification in await rpc.notifications {
        switch notification.method {
        case "redraw":
          for parameter in notification.parameters {
            let batch = try UIEventBatch(parameter)
            await sendUIEventBatch(batch)
          }

        default:
          break
        }
      }
    }
  }

  public let uiEventBatches: AsyncStream<UIEventBatch>

  let task: Task<Void, Error>

  func call<Success>(
    method: String,
    withParameters parameters: [Value],
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

  private let rpc: RPC
}
