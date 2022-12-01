//
//  RPCService.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import AsyncAlgorithms
import Backbone
import Collections
import Foundation

public protocol RPCServiceProtocol {
  func run() async throws
  func notifications() async -> AnyAsyncSequence<Notification>
  func call(method: String, parameters: [Value]) async -> Response
}

public actor RPCService: RPCServiceProtocol {
  public init(packer: PackerProtocol, unpacker: UnpackerProtocol) {
    self.packer = packer
    self.unpacker = unpacker
  }

  public func run() async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
      group.addTask {
        for try await unpackedBatch in await self.unpacker.unpackedBatches() {
          guard !Task.isCancelled else {
            return
          }

          try await self.process(
            unpackedBatch: unpackedBatch
          )
        }
      }

      group.addTask {
        try await self.unpacker.run()
      }

      group.addTask {
        try await self.packer.run()
      }

      try await group.waitForAll()
    }
  }

  public func notifications() -> AnyAsyncSequence<Notification> {
    self.notificationChannel.eraseToAnyAsyncSequence()
  }

  @discardableResult
  public func call(method: String, parameters: [Value]) async -> Response {
    let id = Request.ID(self.callsCount)
    self.callsCount += 1

    return await withUnsafeContinuation { continuation in
      Task {
        await self.responseWaiters.register(id: id) { response in
          continuation.resume(returning: response)
        }

        let request = Request(
          id: id,
          method: method,
          parameters: parameters
        )
        await self.packer.pack(value: request.makeValue())
      }
    }
  }

  private let packer: PackerProtocol
  private let unpacker: UnpackerProtocol
  private let notificationChannel = AsyncChannel<Notification>()
  private let responseWaiters = ResponseWaiters()
  private var callsCount = 0

  private func process(unpackedBatch: [Value]) async throws {
    for value in unpackedBatch {
      guard var value = value as? [Value] else {
        throw MessageRPCError.receivedMessageIsNotArray
      }

      guard !value.isEmpty, let type = value.removeFirst() as? Int else {
        throw MessageRPCError.failedParsingArray
      }

      switch type {
      case 0:
        throw MessageRPCError.unexpectedRPCRequest

      case 1:
        guard !value.isEmpty, let rawID = value.removeFirst() as? Int else {
          throw MessageRPCError.failedParsingArray
        }
        let id = Response.ID(rawID)

        guard value.count == 2 else {
          throw MessageRPCError.failedParsingArray
        }

        let (isSuccess, payload) = {
          if value[0] != nil {
            return (false, value[0])

          } else {
            return (true, value[1])
          }
        }()
        await self.responseWaiters.yield(
          .init(
            id: id,
            isSuccess: isSuccess,
            payload: payload
          )
        )

      case 2:
        guard !value.isEmpty, let method = value.removeFirst() as? String else {
          throw MessageRPCError.failedParsingArray
        }

        guard !value.isEmpty, let parameters = value.removeFirst() as? [Value] else {
          throw MessageRPCError.failedParsingArray
        }

        await self.notificationChannel.send(
          .init(
            method: method,
            parameters: parameters
          )
        )

      default:
        throw MessageRPCError.unexpectedRPCEvent
      }
    }
  }
}

private actor ResponseWaiters {
  typealias Callback = @Sendable (Response) -> Void

  func register(id: Request.ID, _ callback: @escaping Callback) {
    self.backingStore[id] = callback
  }

  func yield(_ response: Response) {
    guard let callback = self.backingStore.removeValue(forKey: response.id) else {
      assertionFailure("No waiter for response: \(response)")
      return
    }

    callback(response)
  }

  private var backingStore = TreeDictionary<Request.ID, Callback>()
}

public enum MessageRPCError: Error {
  case receivedMessageIsNotArray
  case failedParsingArray
  case unexpectedRPCRequest
  case unexpectedRPCEvent
}

public struct MessageRPCRequestError: Error {
  public let payload: Any?
}
