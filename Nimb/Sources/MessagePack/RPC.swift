// SPDX-License-Identifier: MIT

import Algorithms
import CasePaths
import Collections
import Combine
import Synchronization
import CustomDump
import Foundation
import Queue

public final class RPC<Target: Channel>: Sendable {
  public let notifications: AsyncThrowingStream<[Message.Notification], any Error>

  private let target: Target
  private let storage = Storage()
  private let packer = Mutex<Packer>(.init())
  private let queue = AsyncQueue()

  public init(_ target: Target) {
    self.target = target

    notifications = AsyncThrowingStream<[Message.Notification], any Error> { [target, storage] continuation in
      Task {
        var notifications = [Message.Notification]()

        let unpacker = Unpacker()

        for try await data in target.dataBatches {
          guard !Task.isCancelled else {
            break
          }

          let messages = try unpacker.unpack(data)
            .map { try Message(value: $0) }

          for message in messages {
            switch message {
            case let .request(request):
              logger.warning("Unexpected msgpack request received: \(String(customDumping: request))")

            case let .response(response):
              storage.responseReceived(response, forRequestWithID: response.id)

            case let .notification(notification):
              notifications.append(notification)
            }
          }

          if !notifications.isEmpty {
            continuation.yield(notifications)
            notifications.removeAll(keepingCapacity: true)
          }
        }

        continuation.finish()
      }
    }
  }

  @discardableResult
  public func call(
    method: String,
    withParameters parameters: [Value]
  ) async
  -> Message.Response.Result {
    await withUnsafeContinuation { continuation in
      Task {
        let request = Message.Request(
          id: storage.announceRequest {
            continuation.resume(returning: $0.result)
          },
          method: method,
          parameters: parameters
        )
        send(request: request)
      }
    }
  }

  public func fastCall(
    method: String,
    withParameters parameters: [Value]
  ) {
    send(
      request: .init(
        id: storage.announceRequest(),
        method: method,
        parameters: parameters
      )
    )
  }

  public func fastCallsTransaction(with calls: some Sequence<(
    method: String,
    parameters: [Value]
  )> & Sendable) {
    let messages = calls.map { call in
      Message.Request(
        id: storage.announceRequest(),
        method: call.method,
        parameters: call.parameters
      )
    }

    let data = packer.withLock { packer in
      var data = Data()

      for message in messages {
        data.append(
          packer.pack(
            message.makeValue()
          )
        )
      }

      return data
    }

    try? target.write(data)
  }

  public func send(request: Message.Request) {
    let data = packer.withLock {
      $0.pack(request.makeValue())
    }

    try? target.write(data)
  }
}

private final class Storage: Sendable {
  private struct State {
    let maximumConcurrentRequests = Int.max
    var currentRequests = IntKeyedDictionary<@Sendable (Message.Response) -> Void>()
    var announcedRequestsCount = 0
  }

  private let state = Mutex<State>(.init())

  func announceRequest(
    _ handler: (@Sendable (Message.Response) -> Void)? =
      nil
  )
    -> Int
  {
    state.withLock { state in
      let id = state.announcedRequestsCount

      (state.announcedRequestsCount, _) = (state.announcedRequestsCount + 1)
        .remainderReportingOverflow(dividingBy: state.maximumConcurrentRequests)

      if let handler {
        state.currentRequests[id] = handler
      }

      return id
    }
  }

  func responseReceived(
    _ response: Message.Response,
    forRequestWithID id: Int
  ) {
    let handler = state.withLock { state in
      let handler = state.currentRequests[id]
      state.currentRequests[id] = nil
      return handler
    }

    guard let handler else {
      return
    }

    handler(response)
  }
}
