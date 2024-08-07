// SPDX-License-Identifier: MIT

import Algorithms
import AsyncAlgorithms
import CasePaths
import Collections
import CustomDump
import Foundation

@MainActor
public class RPC<Target: Channel> {
  public init(_ target: Target, maximumConcurrentRequests: Int) {
    self.target = target
    store = .init(maximumConcurrentRequests: maximumConcurrentRequests)
    messageBatches = .init(target.dataBatches, unpacker: unpacker)
  }

  @discardableResult
  public func call(
    method: String,
    withParameters parameters: [Value]
  ) async throws
    -> Message.Response.Result
  {
    await withUnsafeContinuation { continuation in
      Task {
        try send(
          request: .init(
            id: store.announceRequest {
              continuation.resume(returning: $0.result)
            },
            method: method,
            parameters: parameters
          )
        )
      }
    }
  }

  public func fastCall(
    method: String,
    withParameters parameters: [Value]
  ) throws {
    try send(
      request: .init(
        id: store.announceRequest(),
        method: method,
        parameters: parameters
      )
    )
  }

  public func fastCallsTransaction(with calls: some Sequence<(
    method: String,
    parameters: [Value]
  )>) throws {
    var data = Data()

    for call in calls {
      data.append(
        packer.pack(
          Message.Request(
            id: store.announceRequest(),
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

  private let target: Target
  private let store: Storage
  private let packer = Packer()
  private let unpacker = Unpacker()
  private let messageBatches: AsyncMessageBatches<Target.S>
}

extension RPC: AsyncSequence {
  public typealias Element = [Message.Notification]

  public nonisolated func makeAsyncIterator() -> AsyncIterator {
    .init(
      store: store,
      messageBatchesIterator: messageBatches.makeAsyncIterator()
    )
  }

  public struct AsyncIterator: AsyncIteratorProtocol {
    fileprivate init(
      store: Storage,
      messageBatchesIterator: AsyncMessageBatches<Target.S>.AsyncIterator
    ) {
      self.store = store
      self.messageBatchesIterator = messageBatchesIterator
    }

    public mutating func next() async throws -> [Message.Notification]? {
      while true {
        guard let messages = try await messageBatchesIterator.next() else {
          return nil
        }

        try Task.checkCancellation()

        accumulator.removeAll(keepingCapacity: true)

        for message in messages {
          switch message {
          case let .request(request):
            throw Failure("Unexpected request message received \(request)")

          case let .response(response):
            await store.responseReceived(
              response,
              forRequestWithID: response.id
            )

          case let .notification(notification):
            accumulator.append(notification)
          }
        }

        if !accumulator.isEmpty {
          return accumulator
        }
      }
    }

    private let store: Storage
    private var messageBatchesIterator: AsyncMessageBatches<Target.S>
      .AsyncIterator
    private var accumulator = [Message.Notification]()
  }
}

@MainActor
private class Storage {
  init(maximumConcurrentRequests: Int) {
    self.maximumConcurrentRequests = maximumConcurrentRequests
    currentRequests = .init(repeating: nil, count: maximumConcurrentRequests)
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

  private let maximumConcurrentRequests: Int
  private var currentRequests: [(@Sendable (Message.Response) -> Void)?]
  private var announcedRequestsCount = 0
}
