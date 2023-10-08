// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import CasePaths
import Collections
import CustomDump
import Foundation
import Library

public struct RPC<Target: Channel>: Sendable {
  public init(_ target: Target) {
    self.target = target
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
        try await send(
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

  public func fastCall(method: String, withParameters parameters: [Value]) async throws {
    try await send(
      request: .init(
        id: store.announceRequest(),
        method: method,
        parameters: parameters
      )
    )
  }

  public func fastCallsTransaction(with calls: some Sequence<(method: String, parameters: [Value])>) async throws {
    var data = Data()

    for call in calls {
      await data.append(
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

    try await target.write(data)
  }

  public func send(request: Message.Request) async throws {
    let data = await packer.pack(
      request.makeValue()
    )
    try await target.write(data)
  }

  private let target: Target
  private let packer = Packer()
  private let store = Store()
  private let messageBatches: AsyncMessageBatches<Target.S>
}

extension RPC: AsyncSequence {
  public typealias Element = [Message.Notification]

  public func makeAsyncIterator() -> AsyncIterator {
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
          return nil
        }

        try Task.checkCancellation()

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

    private let store: Store
    private var messageBatchesIterator: AsyncMessageBatches<Target.S>.AsyncIterator
  }
}

private actor Store {
  func announceRequest(_ handler: (@Sendable (Message.Response) -> Void)? = nil) -> Int {
    let id = announcedRequestsCount
    announcedRequestsCount += 1

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

  private var announcedRequestsCount = 0
  private var currentRequests = TreeDictionary < Int, @Sendable (Message.Response) -> Void > ()
}
