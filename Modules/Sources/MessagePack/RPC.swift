// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import CasePaths
import Collections
import CustomDump
import Foundation
import Library

public class RPC<Target: Channel> {
  public init(_ target: Target, loopedRequestsCount: Int) {
    self.target = target
    store = .init(loopedRequestsCount: loopedRequestsCount)
    messageBatches = .init(target.dataBatches)
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

  public func fastCall(method: String, withParameters parameters: [Value]) throws {
    try send(
      request: .init(
        id: store.announceRequest(),
        method: method,
        parameters: parameters
      )
    )
  }

  public func fastCallsTransaction(with calls: some Sequence<(method: String, parameters: [Value])>) throws {
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
  private let store: Store
  private let packer = Packer()
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
    fileprivate init(store: Store, messageBatchesIterator: AsyncMessageBatches<Target.S>.AsyncIterator) {
      self.store = store
      self.messageBatchesIterator = messageBatchesIterator
    }

    public mutating func next() async throws -> [Message.Notification]? {
      var accumulator = [Message.Notification]()

      while true {
        guard let messages = try await messageBatchesIterator.next() else {
          return accumulator.isEmpty ? nil : accumulator
        }

        try Task.checkCancellation()

        for message in messages {
          switch message {
          case let .request(request):
            throw Failure("Unexpected request message received \(request)")

          case let .response(response):
            store.responseReceived(
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

    private let store: Store
    private var messageBatchesIterator: AsyncMessageBatches<Target.S>.AsyncIterator
  }
}

private class Store {
  init(loopedRequestsCount: Int) {
    self.loopedRequestsCount = loopedRequestsCount
  }

  func announceRequest(_ handler: (@Sendable (Message.Response) -> Void)? = nil) -> Int {
    let id = announcedRequestsCount

    (announcedRequestsCount, _) = (announcedRequestsCount + 1)
      .remainderReportingOverflow(dividingBy: loopedRequestsCount)

    if let handler {
      currentRequests[id] = handler
    }
    return id
  }

  func responseReceived(_ response: Message.Response, forRequestWithID id: Int) {
    guard let handler = currentRequests.removeValue(forKey: id) else {
      return
    }

    handler(response)
  }

  private let loopedRequestsCount: Int
  private var announcedRequestsCount = 0
  private var currentRequests = TreeDictionary<Int, @Sendable (Message.Response) -> Void>()
}
