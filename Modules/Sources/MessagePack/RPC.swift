// Copyright © 2022 foxacid7cd. All rights reserved.

import AsyncAlgorithms
import CasePaths
import Collections
import Foundation
import Library

public struct RemoteError: Error {
  public var value: Value
}

public actor RPC {
  public init(_ channel: some Channel) {
    self.channel = channel

    let packer = Packer()
    self.packer = packer

    let unpacker = Unpacker()
    self.unpacker = unpacker

    let store = Store()
    self.store = store

    let (sendNotification, notifications) = AsyncChannel<(method: String, parameters: [Value])>
      .pipe()
    self.notifications = notifications

    task = Task {
      for try await data in await channel.dataBatches {
        if Task.isCancelled {
          break
        }

        for message in try await unpacker.unpack(data) {
          guard
            let array = (/Value.array).extract(from: message)
          else {
            throw RPCError.receivedMessageIsNotArray
          }

          guard
            let firstValue = array.first,
            let integer = (/Value.integer).extract(from: firstValue),
            let messageType = MessageType(rawValue: integer)
          else {
            throw RPCError.failedParsingArray
          }

          switch messageType {
          case .request:
            throw RPCError.unsupportedMessage

          case .response:
            guard
              array.count == 4,
              let id = (/Value.integer).extract(from: array[1])
            else {
              throw RPCError.failedParsingArray
            }

            let result: Result<Value, RemoteError>
            if array[2] != .nil {
              result = .failure(.init(value: array[2]))

            } else {
              result = .success(array[3])
            }

            await store.responseReceived(result, forRequestWithID: id)

          case .notification:
            guard
              array.count == 3,
              let method = (/Value.string).extract(from: array[1]),
              let parameters = (/Value.array).extract(from: array[2])
            else {
              throw RPCError.failedParsingArray
            }

            await sendNotification((method, parameters))
          }
        }
      }
    }
  }

  public let notifications: AsyncStream<(method: String, parameters: [Value])>
  public let task: Task<Void, Error>

  @discardableResult
  public func call(
    method: String,
    withParameters parameters: [Value]
  ) async throws -> Result<Value, RemoteError> {
    await withUnsafeContinuation { continuation in
      Task {
        let id = await store.announceRequest { response in
          continuation.resume(returning: response)
        }
        let request: Value = .array([
          .integer(MessageType.request.rawValue),
          .integer(id),
          .string(method),
          .array(parameters),
        ])
        let data = await packer.pack(request)
        return try await channel.write(data)
      }
    }
  }

  private actor Store {
    func announceRequest(
      _ handler: @escaping @Sendable (Result<Value, RemoteError>)
        -> Void
    )
      -> Int {
      let id = announcedRequestsCount
      announcedRequestsCount += 1

      currentRequests[id] = handler
      return id
    }

    func responseReceived(
      _ response: Result<Value, RemoteError>,
      forRequestWithID id: Int
    ) {
      guard let handler = currentRequests.removeValue(forKey: id)
      else {
        assertionFailure("Missing response handler for request with id \(id).")
        return
      }

      handler(response)
    }

    private var announcedRequestsCount = 0
    private var currentRequests = TreeDictionary < Int,
                @Sendable (Result<Value, RemoteError>) -> Void> ()
  }

  private enum MessageType: Int {
    case request = 0
    case response
    case notification
  }

  private let channel: any Channel
  private let packer: Packer
  private let unpacker: Unpacker
  private let store: Store
}

public enum RPCError: Error {
  case receivedMessageIsNotArray
  case failedParsingArray
  case invalidRequest
  case unsupportedMessage
}
