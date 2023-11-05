// SPDX-License-Identifier: MIT

import Library
import MessagePack

public struct API<Target: Channel>: Sendable {
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

  public func fastCall<T: Nims.APIFunction>(_ apiFunction: T) async throws {
    try await rpc.fastCall(
      method: T.method,
      withParameters: apiFunction.parameters
    )
  }

  public func fastCallsTransaction(with apiFunctions: some Sequence<any APIFunction>) async throws {
    try await rpc.fastCallsTransaction(with: apiFunctions.map {
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
      var rawRedrawNotificationParameters = [Value]()

      while true {
        if let notifications = try await rpcIterator.next() {
          try Task.checkCancellation()

          for notification in notifications {
            guard notification.method == "redraw" else {
              throw Failure("Unknown neovim API method \(notification.method)")
            }

            rawRedrawNotificationParameters += notification.parameters
          }

          if isLastEventFlush(rawRedrawNotificationParameters: rawRedrawNotificationParameters) {
            return try await makeUIEvents(
              rawRedrawNotificationParameters: rawRedrawNotificationParameters
            )
          }
        } else if !rawRedrawNotificationParameters.isEmpty {
          return try await makeUIEvents(
            rawRedrawNotificationParameters: rawRedrawNotificationParameters
          )
        } else {
          return nil
        }
      }
    }

    private var rpcIterator: RPC<Target>.AsyncIterator

    private func isLastEventFlush(rawRedrawNotificationParameters: [Value]) -> Bool {
      guard 
        case let .array(array) = rawRedrawNotificationParameters.last,
        case let .string(uiEventName) = array.first,
        uiEventName == "flush"
      else {
        return false
      }
      return true
    }

    private func makeUIEvents(rawRedrawNotificationParameters: [Value]) async throws -> [UIEvent] {
      if rawRedrawNotificationParameters.count <= 100 {
        try [UIEvent](rawRedrawNotificationParameters: rawRedrawNotificationParameters)
      } else {
        try await withThrowingTaskGroup(of: (index: Int, uiEvents: [UIEvent]).self) { taskGroup in
          let chunkSize = rawRedrawNotificationParameters.optimalChunkSize(preferredChunkSize: 100)
          let chunks = rawRedrawNotificationParameters.chunks(ofCount: chunkSize)

          for (index, chunk) in chunks.enumerated() {
            taskGroup.addTask {
              try (
                index: index,
                uiEvents: [UIEvent](rawRedrawNotificationParameters: chunk)
              )
            }
          }

          var accumulator = [[UIEvent]](repeating: [], count: chunks.count)
          for try await (index, uiEvents) in taskGroup {
            accumulator[index] = uiEvents
          }
          return accumulator.flatMap { $0 }
        }
      }
    }
  }
}
