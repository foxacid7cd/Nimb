// Copyright © 2022 foxacid7cd. All rights reserved.

import AsyncAlgorithms
import CasePaths
import MessagePack

public actor API {
  public init(
    _ channel: some Channel
  ) {
    let rpc = RPC(channel)
    self.rpc = rpc

    let (sendUIEventBatch, uiEventBatches) = AsyncChannel<UIEventBatch>.pipe()
    self.uiEventBatches = uiEventBatches

    task = Task {
      for try await notification in await rpc.notifications {
        guard !Task.isCancelled else { return }

        switch notification.method {
        case "redraw":
          for parameter in notification.parameters {
            let batch = try UIEventBatch(parameter)
            await sendUIEventBatch(batch)
          }

        default: break
        }
      }
    }
  }

  public enum CallFailed: Error { case invalidAssumedSuccessResponseType(description: String) }

  public let uiEventBatches: AsyncStream<UIEventBatch>

  let task: Task<Void, Error>

  func call<Success>(
    method: String,
    withParameters parameters: [Value],
    transformSuccess: (Value) -> Success?
  ) async throws -> Result<Success, RemoteError> {
    let result = try await rpc.call(method: method, withParameters: parameters)

    switch result {
    case let .success(rawSuccess):
      guard let success = transformSuccess(rawSuccess) else {
        throw CallFailed.invalidAssumedSuccessResponseType(
          description:
            "Assumed: \(String(reflecting: Success.self)), received: \(String(reflecting: rawSuccess))"
        )
      }

      return .success(success)

    case let .failure(error): return .failure(error)
    }
  }

  private let rpc: RPC
}
