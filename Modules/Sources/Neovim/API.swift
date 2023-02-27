// SPDX-License-Identifier: MIT

import MessagePack

public actor API {
  public init(_ channel: some Channel) {
    rpc = .init(channel)
  }

  public var uiEventBatches: AsyncThrowingStream<[UIEvent], Error> {
    .init { continuation in
      let task = Task {
        do {
          for try await (method, parameters) in await rpc.notifications {
            guard !Task.isCancelled else {
              return
            }

            guard method == "redraw" else {
              assertionFailure("Unknown neovim API method \(method)")
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

  let rpc: RPC
}
