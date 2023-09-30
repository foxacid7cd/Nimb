// SPDX-License-Identifier: MIT

import Library
import MessagePack

public struct API<Target: Channel>: Sendable {
  public init(_ rpc: RPC<Target>) {
    self.rpc = rpc
  }

  let rpc: RPC<Target>
}

extension API: AsyncSequence {
  public typealias Element = [UIEvent]

  public func makeAsyncIterator() -> AsyncIterator {
    .init(rpc.makeAsyncIterator())
  }

  public struct AsyncIterator: AsyncIteratorProtocol {
    init(_ rpcIterator: RPC<Target>.AsyncIterator) {
      self.rpcIterator = rpcIterator
    }

    public mutating func next() async throws -> [UIEvent]? {
      var accumulator = [UIEvent]()

      while true {
        guard let notifications = try await rpcIterator.next() else {
          return nil
        }

        try Task.checkCancellation()

        for notification in notifications {
          guard notification.method == "redraw" else {
            throw Failure("Unknown neovim API method \(notification.method)")
          }

          let uiEvents = try [UIEvent](
            rawRedrawNotificationParameters: notification.parameters
          )
          accumulator += uiEvents
        }

        if !accumulator.isEmpty {
          return accumulator
        }
      }
    }

    private var rpcIterator: RPC<Target>.AsyncIterator
  }
}
