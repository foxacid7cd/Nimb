// Copyright © 2022 foxacid7cd. All rights reserved.

import AsyncAlgorithms
import Backbone
import Collections
import Foundation

public protocol RPCServiceProtocol: AnyActor {
  var notifications: AsyncStream<Notification> { get async }
  func call(method: String, parameters: [Value]) async throws -> Response
}

public protocol RPCChannel {
  var dataBatches: AsyncStream<Void> { get async }
  func write(_ data: Data) async throws
}

public actor RPCService: RPCServiceProtocol {
  public init(
    packer: PackerProtocol = Packer(),
    unpacker: UnpackerProtocol = Unpacker(),
    channel: RPCChannel
  ) {
    self.packer = packer
    self.unpacker = unpacker
    self.channel = channel
    (sendNotification, notifications) = AsyncChannel<Notification>.pipe()
  }

  public let notifications: AsyncStream<Notification>

  @discardableResult
  public func call(method: String, parameters: [Value]) async throws -> Response {
    await withUnsafeContinuation { continuation in
      Task {
        let id = await self.store.announceRequest { response in
          continuation.resume(returning: response)
        }

        let request = Request(
          id: id,
          method: method,
          parameters: parameters
        )

        let data = await self.packer.pack(request.makeValue())
        try await self.channel.write(data)
      }
    }
  }

  private actor Store {
    func announceRequest(_ responseReceived: @escaping @Sendable (Response) -> Void) -> Request.ID {
      let id = Request.ID(requestCounter)
      requestCounter += 1

      responseWaiters[id] = responseReceived
      return id
    }

    func responseReceived(_ response: Response) {
      guard let resolveWaiter = responseWaiters.removeValue(forKey: response.id)
      else {
        assertionFailure("Missing response handler for id \(response.id).")
        return
      }

      resolveWaiter(response)
    }

    private var requestCounter = 0
    private var responseWaiters = TreeDictionary < Request.ID, @Sendable (Response) -> Void > ()
  }

  private let packer: PackerProtocol
  private let unpacker: UnpackerProtocol
  private let channel: RPCChannel
  private let store = Store()
  private let sendNotification: @Sendable (Notification) async -> Void

  private func process(unpackedBatch: [Value]) async throws {
    for value in unpackedBatch {
      guard var value = value as? [Value]
      else {
        throw MessageRPCError.receivedMessageIsNotArray
      }

      guard !value.isEmpty, let type = value.removeFirst() as? Int
      else {
        throw MessageRPCError.failedParsingArray
      }

      switch type {
      case 0:
        throw MessageRPCError.unexpectedRPCRequest

      case 1:
        guard !value.isEmpty, let rawID = value.removeFirst() as? Int
        else {
          throw MessageRPCError.failedParsingArray
        }
        let id = Response.ID(rawID)

        guard value.count == 2
        else {
          throw MessageRPCError.failedParsingArray
        }

        let (isSuccess, payload) = {
          if value[0] != nil {
            return (false, value[0])
          } else {
            return (true, value[1])
          }
        }()
        let response = Response(
          id: id,
          isSuccess: isSuccess,
          payload: payload
        )
        await store.responseReceived(response)

      case 2:
        guard !value.isEmpty, let method = value.removeFirst() as? String
        else {
          throw MessageRPCError.failedParsingArray
        }

        guard !value.isEmpty, let parameters = value.removeFirst() as? [Value]
        else {
          throw MessageRPCError.failedParsingArray
        }

        await sendNotification(.init(method: method, parameters: parameters))

      default:
        throw MessageRPCError.unexpectedRPCEvent
      }
    }
  }
}

public enum MessageRPCError: Error {
  case receivedMessageIsNotArray
  case failedParsingArray
  case unexpectedRPCRequest
  case unexpectedRPCEvent
}
