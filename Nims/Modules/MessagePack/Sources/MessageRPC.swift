//
//  MessageRPC.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import AsyncAlgorithms
import Backbone
import Foundation

public actor MessageRPC {
  public init(packer: MessagePackerProtocol, unpacker: MessageUnpackerProtocol) {
    self.packer = packer
    self.unpacker = unpacker
  }

  deinit {
    self.task?.cancel()
  }

  public var notifications: AnyAsyncThrowingSequence<RPCNotification> {
    self.notificationChannel.eraseToAnyAsyncThrowingSequence()
  }

  public func start() async {
    guard self.task == nil else {
      return
    }

    self.task = Task {
      do {
        for try await messageValues in await self.unpacker.messageValueBatches() {
          guard !Task.isCancelled else {
            return
          }

          try await self.handle(messageValues: messageValues)
        }

        self.notificationChannel.finish()

      } catch {
        self.notificationChannel.fail(error)
      }
    }
  }

  @discardableResult
  public func request(method: String, parameters: [MessageValue]) async throws -> MessageValue {
    let id = self.requestCounter
    self.requestCounter += 1

    return try await withUnsafeThrowingContinuation { continuation in
      let request = RPCRequest(id: id, method: method, parameters: parameters)

      let responseHandler = { (isSuccess: Bool, payload: MessageValue) in
        if isSuccess {
          continuation.resume(with: .success(payload))

        } else {
          let error = MessageRPCRequestError(payload: payload)
          continuation.resume(with: .failure(error))
        }
      }
      self.register(resposeHandler: responseHandler, forRequestID: id)

      Task {
        do {
          try await self.packer.pack(messageValue: request.messageValueEncoded)

        } catch {
          self.task?.cancel()

          self.notificationChannel.fail(error)
        }
      }
    }
  }

  private var responseHandlers = [Int: (isSuccess: Bool, payload: MessageValue) -> Void]()
  private let packer: MessagePackerProtocol
  private let unpacker: MessageUnpackerProtocol
  private let notificationChannel = AsyncThrowingChannel<RPCNotification, Error>()
  private var requestCounter = 0

  private var task: Task<Void, Never>?

  private func handle(messageValues: [MessageValue]) async throws {
    for messageValue in messageValues {
      guard var arrayValue = messageValue as? [MessageValue] else {
        throw MessageRPCError.receivedMessageIsNotArray
      }

      guard !arrayValue.isEmpty, let intValue = arrayValue.removeFirst() as? Int else {
        throw MessageRPCError.failedParsingArray
      }

      switch intValue {
      case 0:
        throw MessageRPCError.unexpectedRPCRequest

      case 1:
        guard !arrayValue.isEmpty, let responseID = arrayValue.removeFirst() as? Int else {
          throw MessageRPCError.failedParsingArray
        }

        guard arrayValue.count == 2 else {
          throw MessageRPCError.failedParsingArray
        }

        if let handler = responseHandler(responseID: responseID) {
          if arrayValue[0] != nil {
            handler(false, arrayValue[0])

          } else {
            handler(true, arrayValue[1])
          }
        }

      case 2:
        guard !arrayValue.isEmpty, let method = arrayValue.removeFirst() as? String else {
          throw MessageRPCError.failedParsingArray
        }

        guard !arrayValue.isEmpty, let parameters = arrayValue.removeFirst() as? [MessageValue] else {
          throw MessageRPCError.failedParsingArray
        }

        let notification = RPCNotification(
          method: method,
          parameters: parameters
        )

        await self.notificationChannel.send(notification)

      default:
        throw MessageRPCError.unexpectedRPCEvent
      }
    }
  }

  private func register(
    resposeHandler: @escaping (_ isSuccess: Bool, _ payload: Any?) -> Void,
    forRequestID id: Int
  ) {
    self.responseHandlers[id] = resposeHandler
  }

  private func responseHandler(responseID: Int) -> ((_ isSuccess: Bool, _ payload: Any?) -> Void)? {
    self.responseHandlers.removeValue(forKey: responseID)
  }
}

public protocol MessageRPCTarget {
  var messageValueBatches: AnyAsyncThrowingSequence<[MessageValue]> { get }

  func write(messageValue: MessageValue) async throws
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
