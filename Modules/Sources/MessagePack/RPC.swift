// Copyright © 2022 foxacid7cd. All rights reserved.

import AsyncAlgorithms
import Collections
import Foundation
import Library
import Tagged

public typealias Notification = (method: String, parameters: [MessageValue])

public struct RemoteError: Error {
  public var messageValue: MessageValue
}

public actor RPC {
  public init(_ channel: some Channel) {
    let store = Store()

    let (sendNotification, notifications) = AsyncChannel<Notification>.pipe()
    self.notifications = notifications

    runTask = Task { [channel, unpacker] in
      let dataBatches = await channel.dataBatches

      for try await data in dataBatches {
        if Task.isCancelled {
          break
        }

        let messageValues = try await unpacker.unpack(data)

        for value in messageValues {
          guard var value = value as? [MessageValue]
          else {
            throw RPCError.receivedMessageIsNotArray
          }

          guard !value.isEmpty, let type = value.removeFirst() as? Int
          else {
            throw RPCError.failedParsingArray
          }

          switch type {
          case MessageType.request.rawValue:
            throw RPCError.unexpectedRPCRequest

          case MessageType.response.rawValue:
            guard !value.isEmpty, let rawRequestID = value.removeFirst() as? Int
            else {
              throw RPCError.failedParsingArray
            }
            let requestID = Request.ID(rawRequestID)

            guard value.count == 2
            else {
              throw RPCError.failedParsingArray
            }

            let response: Result<MessageValue, RemoteError>
            if value[0] != nil {
              response = .failure(.init(messageValue: value[0]))

            } else {
              response = .success(value[1])
            }

            await store.responseReceived(response, forRequestWithID: requestID)

          case MessageType.notification.rawValue:
            guard !value.isEmpty, let method = value.removeFirst() as? String
            else {
              throw RPCError.failedParsingArray
            }

            guard !value.isEmpty, let parameters = value.removeFirst() as? [MessageValue]
            else {
              throw RPCError.failedParsingArray
            }

            await sendNotification((method, parameters))

          default:
            throw RPCError.unexpectedRPCEvent
          }
        }
      }
    }

    self.channel = channel
    self.store = store
  }

  public let notifications: AsyncStream<Notification>

  public func value() async throws {
    try await runTask.value
  }

  @discardableResult
  public func call(
    method: String,
    withParameters parameters: [MessageValue]
  ) async throws -> Result<MessageValue, RemoteError> {
    await withUnsafeContinuation { continuation in
      Task {
        let requestID = await store.announceRequest { response in
          continuation.resume(returning: response)
        }
        let requestMessage: MessageValue = [
          MessageType.request.rawValue,
          requestID.rawValue,
          method,
          parameters,
        ]
        let messageData = await packer.pack(requestMessage)
        return try await channel.write(messageData)
      }
    }
  }

  private let channel: any Channel
  private let runTask: Task<Void, Error>
  private let packer = Packer()
  private let unpacker = Unpacker()
  private let store: Store
}

private actor Store {
  func announceRequest(
    _ responseReceived: @escaping @Sendable (Result<MessageValue, RemoteError>)
      -> Void
  )
    -> Request.ID {
    let id = Request.ID(requestCounter)
    requestCounter += 1

    responseWaiters[id] = responseReceived
    return id
  }

  func responseReceived(
    _ response: Result<MessageValue, RemoteError>,
    forRequestWithID requestID: Request.ID
  ) {
    guard let resolveWaiter = responseWaiters.removeValue(forKey: requestID)
    else {
      assertionFailure("Missing response handler for request with id \(requestID).")
      return
    }

    resolveWaiter(response)
  }

  private var requestCounter = 0
  private var responseWaiters = TreeDictionary <Request.ID,
              @Sendable (Result<MessageValue, RemoteError>) -> Void > ()
}

private enum MessageType: Int {
  case request = 0
  case response
  case notification
}

private enum Request {
  typealias ID = Tagged<Request, Int>
}

private enum RPCError: Error {
  case receivedMessageIsNotArray
  case failedParsingArray
  case unexpectedRPCRequest
  case unexpectedRPCEvent
}
