// SPDX-License-Identifier: MIT

import Algorithms
import AsyncAlgorithms
import CasePaths
import Collections
import CustomDump
import Foundation

public final class RPC<Target: Channel>: Sendable {
  public init(_ target: Target, maximumConcurrentRequests: Int) {
    self.target = target
    storage = .init(maximumConcurrentRequests: maximumConcurrentRequests)

    notifications = AsyncThrowingStream<[Message.Notification], any Error> { [storage, target, unpacker] continuation in
      let task = Task {
        var notifications = [Message.Notification]()
        for try await data in target.dataBatches {
          let values = try unpacker.withLock { try $0.unpack(data) }
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

  public let notifications: AsyncThrowingStream<[Message.Notification], any Error>

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
    try packer.withLock { packer in
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
  }

  public func send(request: Message.Request) throws {
    try packer.withLock { packer in
      let data = packer.pack(request.makeValue())
      try target.write(data)
    }
  }

  private let target: Target
  private let storage: Storage
  private let packer = LockIsolated(Packer())
  private let unpacker = LockIsolated(Unpacker())
}

private final class Storage: Sendable {
  init(maximumConcurrentRequests: Int) {
    self.maximumConcurrentRequests = maximumConcurrentRequests
    critical = .init(.init(currentRequests: .init(repeating: nil, count: maximumConcurrentRequests)))
  }

  func announceRequest(
    _ handler: (@Sendable (Message.Response) -> Void)? =
      nil
  )
    -> Int
  {
    critical.withLock { [maximumConcurrentRequests] critical in
      let id = critical.announcedRequestsCount

      (critical.announcedRequestsCount, _) = (critical.announcedRequestsCount + 1)
        .remainderReportingOverflow(dividingBy: maximumConcurrentRequests)

      if let handler {
        critical.currentRequests[id] = handler
      }

      return id
    }
  }

  func responseReceived(
    _ response: Message.Response,
    forRequestWithID id: Int
  ) {
    let handler: (@Sendable (Message.Response) -> Void)? = critical.withLock { critical in
      guard let handler = critical.currentRequests[id] else {
        return nil
      }
      critical.currentRequests[id] = nil
      return handler
    }
    handler?(response)
  }

  private class Critical {
    init(currentRequests: [(@Sendable (Message.Response) -> Void)?], announcedRequestsCount: Int = 0) {
      self.currentRequests = currentRequests
      self.announcedRequestsCount = announcedRequestsCount
    }

    var currentRequests: [(@Sendable (Message.Response) -> Void)?]
    var announcedRequestsCount = 0
  }

  private let maximumConcurrentRequests: Int
  private let critical: LockIsolated<Critical>
}
