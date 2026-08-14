// SPDX-License-Identifier: MIT

import Algorithms
import Collections
import Combine
import CustomDump
import Foundation
import Synchronization

public final class RPC<Target: Channel>: Sendable {
  public let notifications: AsyncThrowingStream<[Message.Notification], any Error>

  private let target: Target
  private let storage = Storage()
  private let packer = Mutex<Packer>(.init())

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
              await storage.responseReceived(response, forRequestWithID: response.id)

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
    withParameters parameters: [Value],
  ) async
  -> Message.Response.Result {
    await withUnsafeContinuation { continuation in
      Task {
        let request = await Message.Request(
          id: storage.announceRequest {
            continuation.resume(returning: $0.result)
          },
          method: method,
          parameters: parameters,
        )
        send(request: request)
      }
    }
  }

  public func fastCall(
    method: String,
    withParameters parameters: [Value],
  ) {
    Task {
      await send(
        request: .init(
          id: storage.announceRequest(),
          method: method,
          parameters: parameters,
        ),
      )
    }
  }

  public func fastCallsTransaction(with calls: some Sequence<(
    method: String,
    parameters: [Value],
  )> & Sendable) {
    Task {
      var messages = [Message.Request]()
      messages.reserveCapacity(calls.underestimatedCount)

      for call in calls {
        await messages.append(
          .init(
            id: storage.announceRequest(),
            method: call.method,
            parameters: call.parameters,
          ),
        )
      }

      let data = packer.withLock { packer in
        var data = Data()

        for message in messages {
          data.append(
            packer.pack(
              message.makeValue(),
            ),
          )
        }

        return data
      }

      try? target.write(data)
    }
  }

  public func send(request: Message.Request) {
    let data = packer.withLock {
      $0.pack(request.makeValue())
    }

    try? target.write(data)
  }
}

@MainActor
private final class Storage {
  private let maximumConcurrentRequests = Int.max
  private var currentRequests = IntKeyedDictionary<@Sendable (Message.Response) -> Void>()
  private var announcedRequestsCount = 0

  func announceRequest(
    _ handler: (@Sendable (Message.Response) -> Void)? =
      nil,
  )
    -> Int
  {
    let id = announcedRequestsCount

    (announcedRequestsCount, _) = (announcedRequestsCount + 1)
      .remainderReportingOverflow(dividingBy: maximumConcurrentRequests)

    if let handler {
      currentRequests[id] = handler
    }

    return id
  }

  func responseReceived(
    _ response: Message.Response,
    forRequestWithID id: Int,
  ) {
    let handler = currentRequests[id]
    currentRequests[id] = nil

    guard let handler else {
      return
    }

    handler(response)
  }
}
