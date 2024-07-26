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
  public typealias Element = NeovimNotification

  public func makeAsyncIterator() -> AsyncIterator {
    .init(rpc.makeAsyncIterator())
  }

  public struct AsyncIterator: AsyncIteratorProtocol {
    init(_ rpcIterator: RPC<Target>.AsyncIterator) {
      self.rpcIterator = rpcIterator
    }

    public mutating func next() async throws -> NeovimNotification? {
      while true {
        if let notifications = try await rpcIterator.next() {
          try Task.checkCancellation()

          for notification in notifications {
            guard notification.method == "redraw" else {
              throw Failure("Unknown neovim API method \(notification.method)")
            }

            switch notification.method {
            case "redraw":
              let uiEvents = try [UIEvent](rawRedrawNotificationParameters: notification.parameters)
              return .redraw(uiEvents)

            case "nvim_error_event":
              let nvimErrorEvent = try NeovimErrorEvent(parameters: notification.parameters)
              return .nvimErrorEvent(nvimErrorEvent)

            default:
              logger.info("Unknown neovim API notification: \(notification.method)")
            }
          }
        } else {
          break
        }
      }

      return nil
    }

    private var rpcIterator: RPC<Target>.AsyncIterator
  }
}
