//
//  MessageRPC.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import Foundation

public class MessageRPC {
  private let send: (MessageValue) async throws -> Void
  private let handleNotification: (RPCNotification) -> Void
  @MainActor
  private var requestCounter: UInt32 = 0
  @MainActor
  private var responseHandlers = [UInt32: (isSuccess: Bool, payload: MessageValue) -> Void]()
  
  public init(
    send: @escaping (MessageValue) async throws -> Void,
    handleNotification: @escaping (RPCNotification) -> Void
  ) {
    self.send = send
    self.handleNotification = handleNotification
  }
  
  @MainActor
  public func handleReceived(value: MessageValue) throws -> Void {
    guard let arrayValue = value as? MessageArrayValue else {
      throw MessageRPCError.receivedMessageIsNotArray
    }
    
    var elements = arrayValue.elements
    
    guard !elements.isEmpty, let integerValue = elements.removeFirst() as? MessageInt64Value else {
      throw MessageRPCError.failedParsingArray
    }
    
    switch integerValue.value {
    case 0:
      throw MessageRPCError.unexpectedRPCRequest
      
    case 1:
      guard !elements.isEmpty, let unsignedIntegerValue = elements.removeFirst() as? MessageInt64Value else {
        throw MessageRPCError.failedParsingArray
      }
      let responseID = unsignedIntegerValue.value
      
      guard elements.count == 2 else {
        throw MessageRPCError.failedParsingArray
      }
      if let handler = self.responseHandler(responseID: UInt32(responseID)) {
        handler(true, elements[0])
      }
      
    case 2:
      guard !elements.isEmpty, let stringValue = elements.removeFirst() as? MessageStringValue else {
        throw MessageRPCError.failedParsingArray
      }
      let method = stringValue.string
      
      guard !elements.isEmpty, let arrayValue = elements.removeFirst() as? MessageArrayValue else {
        throw MessageRPCError.failedParsingArray
      }
      let parameters = arrayValue.elements
      
      self.handleNotification(.init(method: String(method), parameters: parameters))
      
    default:
      throw MessageRPCError.unexpectedRPCEvent
    }
  }
  
  @MainActor @discardableResult
  public func request(method: String, parameters: [MessageValue]) async throws -> MessageValue {
    let id = requestCounter
    requestCounter += 1
    
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
          try await self.send(request)
          
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }
  
  @MainActor
  private func register(
    resposeHandler: @escaping (_ isSuccess: Bool, _ payload: MessageValue) -> Void,
    forRequestID id: UInt32
  ) {
    self.responseHandlers[id] = resposeHandler
  }
  
  @MainActor
  private func responseHandler(responseID: UInt32) -> ((_ isSuccess: Bool, _ payload: MessageValue) -> Void)? {
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
  public let payload: MessageValue
}
