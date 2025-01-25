// SPDX-License-Identifier: MIT

import Algorithms
import CasePaths
import Collections
import Combine
import ConcurrencyExtras
import CustomDump
import Foundation
import Queue

public final class RPC<Target: Channel>: Sendable {
  public let notifications: AsyncThrowingStream<[Message.Notification], any Error>

  private let target: Target
  private let storage = LockIsolated<Storage>(.init())
  private let packer = LockIsolated<Packer>(.init())
  private let unpacker = LockIsolated<Unpacker>(.init())
  private let queue = AsyncQueue()

  public init(_ target: Target, maximumConcurrentRequests: Int) {
    self.target = target

    let dataBatches = target.dataBatches

    notifications = AsyncThrowingStream<[Message.Notification], any Error> { [dataBatches, storage, unpacker] continuation in
      let task = Task {
        var notifications = [Message.Notification]()
        for try await data in dataBatches {
          let messages = try unpacker.withValue {
            try $0.unpack(data)
              .map { try Message(value: $0) }
          }

          for message in messages {
            switch message {
            case let .request(request):
              Task { @MainActor in
                logger.warning("Unexpected msgpack request received: \(String(customDumping: request))")
              }

            case let .response(response):
              storage.withValue {
                $0.responseReceived(response, forRequestWithID: response.id)
              }

            case let .notification(notification):
              notifications.append(notification)
            }
          }
          if !notifications.isEmpty {
            continuation.yield(notifications)
            notifications.removeAll(keepingCapacity: true)
          }
        }
      }

      continuation.onTermination = { _ in
        task.cancel()
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
          id: storage.withValue {
            $0.announceRequest {
              continuation.resume(returning: $0.result)
            }
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
        id: storage.withValue { $0.announceRequest() },
        method: method,
        parameters: parameters
      )
    )
  }

  public func fastCallsTransaction(with calls: some Sequence<(
    method: String,
    parameters: [Value]
  )> & Sendable) {
    let messages = storage.withValue { storage in
      calls.map { call in
        Message.Request(
          id: storage.announceRequest(),
          method: call.method,
          parameters: call.parameters
        )
      }
    }

    let data = packer.withValue { packer in
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
    let data = packer.withValue {
      $0.pack(request.makeValue())
    }

    try? target.write(data)
  }
}

private final class Storage {
  private let maximumConcurrentRequests = Int.max
  private var currentRequests = IntKeyedDictionary<@Sendable (Message.Response) -> Void>()
  private var announcedRequestsCount = 0

  func announceRequest(
    _ handler: (@Sendable (Message.Response) -> Void)? =
      nil
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
    forRequestWithID id: Int
  ) {
    guard let handler = currentRequests[id] else {
      return
    }
    currentRequests[id] = nil
    handler(response)
  }
}
