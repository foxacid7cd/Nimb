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

public protocol RPCProtocol {
  var notifications: AsyncStream<Notification> { get async }
  func call(method: String, withParameters parameters: [MessageValue]) async throws
    -> Result<MessageValue, RemoteError>
}

public actor RPC: RPCProtocol {
  public init(
    packer: PackerProtocol = Packer(),
    unpacker: UnpackerProtocol = Unpacker(),
    channel: Channel
  ) {
    self.packer = packer
    self.unpacker = unpacker
    self.channel = channel
    (sendNotification, notifications) = AsyncChannel<Notification>.pipe()
  }

  public enum Error: Swift.Error {
    case receivedMessageIsNotArray
    case failedParsingArray
    case unexpectedRPCRequest
    case unexpectedRPCEvent
  }

  public let notifications: AsyncStream<Notification>

  @discardableResult
  public func call(
    method: String,
    withParameters parameters: [MessageValue]
  ) async throws -> Result<MessageValue, RemoteError> {
    await withUnsafeContinuation { continuation in
      Task {
        let requestID = await self.store.announceRequest { response in
          continuation.resume(returning: response)
        }
        let requestMessage: MessageValue = [
          MessageType.request.rawValue,
          requestID.rawValue,
          method,
          parameters,
        ]
        let messageData = await self.packer.pack(requestMessage)
        return try await self.channel.write(messageData)
      }
    }
  }

  public func run() async throws {
    let task = Task {
      for await batch in await self.channel.dataBatches {
        if Task.isCancelled {
          break
        }

        let messages = try await self.unpacker.unpack(batch)
        try await self.messagesReceived(messages)
      }
    }

    try await task.value
  }

  private let packer: PackerProtocol
  private let unpacker: UnpackerProtocol
  private let channel: Channel
  private let store = Store()
  private let sendNotification: @Sendable (Notification)
    async -> Void

  private func messagesReceived(_ messages: [MessageValue]) async throws {
    for value in messages {
      guard var value = value as? [MessageValue]
      else {
        throw Error.receivedMessageIsNotArray
      }

      guard !value.isEmpty, let type = value.removeFirst() as? Int
      else {
        throw Error.failedParsingArray
      }

      switch type {
      case MessageType.request.rawValue:
        throw Error.unexpectedRPCRequest

      case MessageType.response.rawValue:
        guard !value.isEmpty, let rawRequestID = value.removeFirst() as? Int
        else {
          throw Error.failedParsingArray
        }
        let requestID = Request.ID(rawRequestID)

        guard value.count == 2
        else {
          throw Error.failedParsingArray
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
          throw Error.failedParsingArray
        }

        guard !value.isEmpty, let parameters = value.removeFirst() as? [MessageValue]
        else {
          throw Error.failedParsingArray
        }

        await sendNotification((method, parameters))

      default:
        throw Error.unexpectedRPCEvent
      }
    }
  }
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
