// SPDX-License-Identifier: MIT

import Algorithms
import AsyncAlgorithms
import CasePaths
import Collections
import CustomDump
import Foundation

@MainActor
public final class RPC<Target: Channel>: Sendable {
  public let notifications: AsyncThrowingStream<[Message.Notification], any Error>

  private let target: Target
  private let storage: Storage
  private let packer = Packer()
  private let unpacker = Unpacker()

  public init(_ target: Target, maximumConcurrentRequests: Int) {
    self.target = target
    storage = .init(maximumConcurrentRequests: maximumConcurrentRequests)

    notifications = AsyncThrowingStream<[Message.Notification], any Error> { [storage, target, unpacker] continuation in
      let task = Task {
        var notifications = [Message.Notification]()
        for try await data in target.dataBatches {
          let values = try unpacker.unpack(data)
          let messages = try values.map { try Message(value: $0) }

          for message in messages {
            switch message {
            case .request:
              continue
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
      }

      continuation.onTermination = {
        switch $0 {
        case .cancelled:
          task.cancel()
        default:
          break
        }
      }
    }
  }

  @discardableResult
  public func call(
    method: String,
    withParameters parameters: [Value]
  ) async throws
  -> Message.Response.Result {
    try await withUnsafeThrowingContinuation { continuation in
      Task {
        let request = Message.Request(
          id: storage.announceRequest {
            continuation.resume(returning: $0.result)
          },
          method: method,
          parameters: parameters
        )
        do {
          try send(request: request)
        } catch { }
      }
    }
  }

  public func fastCall(
    method: String,
    withParameters parameters: [Value]
  ) throws {
    try send(
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
  )> & Sendable) throws {
    var data = Data()

    for call in calls {
      data.append(
        packer.pack(
          Message.Request(
            id: storage.announceRequest(),
            method: call.method,
            parameters: call.parameters
          )
          .makeValue()
        )
      )
    }

    try target.write(data)
  }

  public func send(request: Message.Request) throws {
    let data = packer.pack(request.makeValue())
    try target.write(data)
  }
}

@MainActor
private final class Storage: Sendable {
  private let maximumConcurrentRequests: Int
  private var currentRequests = IntKeyedDictionary<@Sendable (Message.Response) -> Void>()
  private var announcedRequestsCount = 0

  init(maximumConcurrentRequests: Int) {
    self.maximumConcurrentRequests = maximumConcurrentRequests
  }

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
