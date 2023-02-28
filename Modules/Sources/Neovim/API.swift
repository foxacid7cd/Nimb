// SPDX-License-Identifier: MIT

import MessagePack

public struct API<Target: Channel>: AsyncSequence {
  public init(rpc: RPC<Target>) {
    self.rpc = rpc
  }

  private var rpc: RPC<Target>

  public typealias Element = [UIEvent]

  public func makeAsyncIterator() -> AsyncIterator {
    .init(rpcIterator: rpc.makeAsyncIterator())
  }

  public struct AsyncIterator: AsyncIteratorProtocol {
    var rpcIterator: RPC<Target>.AsyncIterator

    public mutating func next() async throws -> [UIEvent]? {
      var accumulator = [UIEvent]()

      while true {
        guard let notifications = try await rpcIterator.next() else {
          return nil
        }

        try Task.checkCancellation()

        for notification in notifications {
          guard notification.method == "redraw" else {
            assertionFailure("Unknown neovim API method \(notification.method).")
            continue
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
  }
}
