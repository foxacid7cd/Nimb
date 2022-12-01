//
//  Facade.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import AsyncAlgorithms
import Backbone
import Collections
import Foundation

public actor Facade {
  public init(packer: PackerProtocol, unpacker: UnpackerProtocol) {
    self.packer = packer
    self.unpacker = unpacker
  }

  public init(writingTo: FileHandle, readingFrom: FileHandle) {
    self.init(
      packer: Packer(dataDestination: writingTo.decorator),
      unpacker: Unpacker(dataSource: readingFrom.decorator)
    )
  }

  public func notifications() -> AnyAsyncThrowingSequence<Notification> {
    let stream = AsyncThrowingStream<Notification, Error> { continuation in
      let task = Task {
        do {
          for try await values in await self.unpacker.valueBatches() {
            guard !Task.isCancelled else {
              return
            }

            try await self.process(
              values: values,
              notificationDecoded: { continuation.yield($0) }
            )
          }

          continuation.finish()

        } catch {
          continuation.finish(throwing: error)
        }
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }

    return stream.eraseToAnyAsyncThrowingSequence()
  }

  @discardableResult
  public func call(method: String, parameters: [Value]) async -> Response {
    let id = Request.ID(self.callsCount)
    self.callsCount += 1

    return await withUnsafeContinuation { continuation in
      let request = Request(id: id, method: method, parameters: parameters)

      Task.detached {
        await self.responseWaiters.register(id: id) { response in
          continuation.resume(returning: response)
        }
      }

      Task {
        try await self.packer.pack(
          value: request.makeValue()
        )
      }
    }
  }

  private let packer: PackerProtocol
  private let unpacker: UnpackerProtocol
  private let responseWaiters = ResponseWaiters()
  private var callsCount = 0

  private func process(
    values: [Value],
    notificationDecoded: @Sendable @escaping (Notification) -> Void
  ) async throws {
    for value in values {
      guard var casted = value as? [Value] else {
        throw MessageRPCError.receivedMessageIsNotArray
      }

      guard !casted.isEmpty, let type = casted.removeFirst() as? Int else {
        throw MessageRPCError.failedParsingArray
      }

      switch type {
      case 0:
        throw MessageRPCError.unexpectedRPCRequest

      case 1:
        guard !casted.isEmpty, let rawID = casted.removeFirst() as? Int else {
          throw MessageRPCError.failedParsingArray
        }
        let id = Response.ID(rawID)

        guard casted.count == 2 else {
          throw MessageRPCError.failedParsingArray
        }

        let (isSuccess, payload) = {
          if casted[0] != nil {
            return (false, casted[0])

          } else {
            return (true, casted[1])
          }
        }()
        await self.responseWaiters.yield(.init(
          id: id,
          isSuccess: isSuccess,
          payload: payload
        ))

      case 2:
        guard !casted.isEmpty, let method = casted.removeFirst() as? String else {
          throw MessageRPCError.failedParsingArray
        }

        guard !casted.isEmpty, let parameters = casted.removeFirst() as? [Value] else {
          throw MessageRPCError.failedParsingArray
        }

        notificationDecoded(.init(
          method: method,
          parameters: parameters
        ))

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
