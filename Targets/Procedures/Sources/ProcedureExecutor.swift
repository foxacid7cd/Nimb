//
//  ProcedureExecutor.swift
//
//
//  Created by Yevhenii Matviienko on 28.09.2022.
//

import Combine
import Conversations
import MessagePack

enum ProcedureExecutorEvent {
  case requestReceived(id: UInt, method: String, params: [MessagePackValue])
  case notificationReceived(method: String, params: [MessagePackValue])
}

@MainActor
public class ProcedureExecutor {
  public var events: AsyncThrowingPublisher<some Publisher> {
    .init(eventsSubject)
  }
  
  private let messageConsumer: MessageConsumer
  private var subscription: Task<Void, Never>?
  private var handlers = [UInt: (ExecutionResult) -> Void]()
  private var procedureCounter: UInt = 0
  private let eventsSubject = PassthroughSubject<ProcedureExecutorEvent, Error>()
  
  public init(messageEmitter: MessageEmitter, messageConsumer: MessageConsumer) {
    self.messageConsumer = messageConsumer
    subscribe(to: messageEmitter)
  }
  
  deinit {
    subscription?.cancel()
  }
  
  private func register(handler: @escaping (ExecutionResult) -> Void, forId id: UInt) {
    handlers[id] = handler
  }
  
  private func unregisterHandler(forId id: UInt) {
    handlers[id] = nil
  }
  
  public func execute(procedure: Procedure) async throws -> ExecutionResult {
    procedureCounter += 1
    let id = procedureCounter
    let consumer = messageConsumer
    return try await withCheckedThrowingContinuation { continuation in
      self.register(handler: { continuation.resume(returning: $0) }, forId: id)
      Task {
        let message = Message.request(id: id, method: procedure.method, params: procedure.params)
        print("Message: ", message)
        do {
          try consumer.consume(message: message)
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }
  
  private func subscribe(to messageEmitter: MessageEmitter) {
    Task { [weak self] in
      do {
        let messages = messageEmitter.messages
        let iterator = messages.makeAsyncIterator()
        while let message = try await iterator.next() {
          print(message)
          guard !Task.isCancelled, let self else {
            break
          }
          
          switch message {
            case let .request(id, method, params):
              self.eventsSubject.send(.requestReceived(id: id, method: method, params: params))
              try self.messageConsumer.consume(
                message: .response(
                  id: id,
                  isSuccess: false,
                  payload: .nil
                )
              )
              
            case let .response(id, isSuccess, payload):
              guard let handler = self.handlers[id] else {
                assertionFailure("Handler for symmetric response message was not registered.")
                continue
              }
              self.unregisterHandler(forId: id)
              handler(.init(isSuccess: isSuccess, payload: payload))
              
            case let .notification(method, params):
              self.eventsSubject.send(.notificationReceived(method: method, params: params))
          }
        }
      } catch {
        self?.eventsSubject.send(completion: .failure(error))
      }
    }
  }
}
