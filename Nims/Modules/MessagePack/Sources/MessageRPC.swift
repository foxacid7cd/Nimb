//
//  MessageRPC.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import AsyncAlgorithms
import Backbone
import Foundation

public class MessageRPC {
  public init(send: @escaping (MessageValue) async -> Void) {
    self.send = send
  }

  public var notifications: AnyAsyncSequence<RPCNotification> {
    self.notificationChannel.eraseToAnyAsyncSequence()
  }

  @MainActor
  public func handleReceived(value: MessageValue) throws {
    guard var arrayValue = value as? [MessageValue] else {
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

      Task {
        await self.notificationChannel.send(notification)
      }

    default:
      throw MessageRPCError.unexpectedRPCEvent
    }
  }

  @MainActor @discardableResult
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
        await self.send(request.messageValueEncoded)
      }
    }
  }

  private var responseHandlers = [Int: (isSuccess: Bool, payload: MessageValue) -> Void]()
  private let send: (MessageValue) async -> Void
  private let notificationChannel = AsyncChannel<RPCNotification>()

  @MainActor
  private var requestCounter = 0

  @MainActor
  private func register(
    resposeHandler: @escaping (_ isSuccess: Bool, _ payload: Any?) -> Void,
    forRequestID id: Int
  ) {
    self.responseHandlers[id] = resposeHandler
  }

  @MainActor
  private func responseHandler(responseID: Int) -> ((_ isSuccess: Bool, _ payload: Any?) -> Void)? {
    self.responseHandlers.removeValue(forKey: responseID)
  }
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
