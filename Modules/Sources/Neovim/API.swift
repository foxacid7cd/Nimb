// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import CasePaths
import MessagePack

public actor API {
  public init(
    _ channel: some Channel
  ) {
    let rpc = RPC(channel)
    self.rpc = rpc

    uiEventBatches = .init { continuation in
      let task = Task {
        do {
          for try await (method, parameters) in await rpc.notifications {
            guard !Task.isCancelled else {
              return
            }

            guard method == "redraw" else {
              continue
            }

            let uiEvents = try [UIEvent](
              rawRedrawNotificationParameters: parameters
            )
            continuation.yield(uiEvents)
          }

          continuation.finish()

        } catch {
          continuation.finish(throwing: error)
        }
      }

      continuation.onTermination = { termination in
        if case .cancelled = termination {
          task.cancel()
        }
      }
    }
  }

  public enum CallFailed: Error { case invalidAssumedSuccessResponseType(description: String) }

  public let uiEventBatches: AsyncThrowingStream<[UIEvent], Error>

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

    case let .failure(error):
      return .failure(error)
    }
  }

  private let rpc: RPC
}
