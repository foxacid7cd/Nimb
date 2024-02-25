// SPDX-License-Identifier: MIT

import Library
import MessagePack

public class API<Target: Channel> {
  public init(_ rpc: RPC<Target>) {
    self.rpc = rpc
  }

  @discardableResult
  public func call<T: Nims.APIFunction>(_ apiFunction: T) async throws -> T.Success {
    try await rpc.call(
      method: T.method,
      withParameters: apiFunction.parameters
    )
    .map(T.decodeSuccess(from:), NeovimError.init(raw:))
  }

  public func fastCall<T: Nims.APIFunction>(_ apiFunction: T) throws {
    try rpc.fastCall(
      method: T.method,
      withParameters: apiFunction.parameters
    )
  }

  public func fastCallsTransaction(with apiFunctions: some Sequence<any APIFunction>) throws {
    try rpc.fastCallsTransaction(with: apiFunctions.map {
      (
        method: type(of: $0).method,
        parameters: $0.parameters
      )
    })
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
        if let notifications = try await rpcIterator.next() {
          try Task.checkCancellation()

          for notification in notifications {
            guard notification.method == "redraw" else {
              throw Failure("Unknown neovim API method \(notification.method)")
            }

            accumulator += try .init(rawRedrawNotificationParameters: notification.parameters)
          }

          if !accumulator.isEmpty {
            return accumulator
          }
        } else {
          return accumulator.isEmpty ? nil : accumulator
        }
      }
    }

    private var rpcIterator: RPC<Target>.AsyncIterator
  }
}
