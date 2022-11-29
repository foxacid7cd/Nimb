//
//  MessageRPC.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import Foundation

public class MessageRPC {
  public init(
    sendMessageValue: @escaping (MessageValue) async throws -> Void,
    handleNotification: @escaping (RPCNotification) -> Void
  ) {
    self.sendMessageValue = sendMessageValue
    self.handleNotification = handleNotification
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

      self.handleNotification(.init(method: String(method), parameters: parameters))

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
        do {
          try await self.sendMessageValue(request.messageValueEncoded)

        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  private var responseHandlers = [Int: (isSuccess: Bool, payload: MessageValue) -> Void]()
  private let sendMessageValue: (MessageValue) async throws -> Void
  private let handleNotification: (RPCNotification) -> Void
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
