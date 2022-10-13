//
//  ProceduringProcess.swift
//  Procedures
//
//  Created by Yevhenii Matviienko on 13.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AsyncAlgorithms
import Conversations
import Foundation
import Library
import MessagePack

public class ProceduringProcess: AsyncSequence {
  public typealias AsyncIterator = AsyncChannel<Element>.Iterator
  public typealias Element = Event
  
  public typealias Handler = (_ isSuccess: Bool, _ payload: MessagePackValue) async -> Void
  
  public enum Event {
    case notificationReceived(Notification)
    case standardError(line: String)
    case terminated(exitCode: Int, reason: Process.TerminationReason)
  }
  
  @MainActor
  private var process: MessagingProcess
  @MainActor
  private var handlers = [UInt: Handler]()
  @MainActor
  private var counter: UInt = 0
  private let eventsChannel = AsyncChannel<Event>()
  
  @MainActor
  public init(executableURL: URL, arguments: [String]) {
    process = .init(executableURL: executableURL, arguments: arguments)
    
    Task {
      for try await message in process {
        switch message {
          case let .standardOutput(message):
            switch message {
              case let .request(id, method, params):
                assertionFailure("Receiving requests not supported, request id: \(id), method: \(method), params: \(params).")
                
              case let .response(id, isSuccess, payload):
                guard let handler = handlers[id] else {
                  fatalError("Handler for request id \(id) is not registered.")
                }
                await handler(isSuccess, payload)
                
              case let .notification(notification):
                await eventsChannel.send(.notificationReceived(notification))
            }
            
          case let .standardError(line):
            await eventsChannel.send(.standardError(line: line))
            
          case let .terminated(exitCode, reason):
            await eventsChannel.send(.terminated(exitCode: exitCode, reason: reason))
        }
      }
    }
  }
  
  @MainActor @discardableResult
  public func request(method: String, params: [MessagePackValue]) async throws -> MessagePackValue {
    return try await withCheckedThrowingContinuation { continuation in
      let id = counter
      counter += 1
      
      self.registerHandler(id: id) { [weak self] isSuccess, payload in
        self?.unregisterHandler(id: id)
        
        if isSuccess {
          continuation.resume(returning: payload)
        } else {
          continuation.resume(throwing: payload)
        }
      }
      
      Task {
        await process.send(.request(id: id, method: method, params: params))
      }
    }
  }
  
  @MainActor
  public func makeAsyncIterator() -> AsyncIterator {
    eventsChannel.makeAsyncIterator()
  }
  
  @MainActor
  private func registerHandler(id: UInt, handler: @escaping Handler) {
    handlers[id] = handler
  }
  
  @MainActor
  private func unregisterHandler(id: UInt) {
    handlers[id] = nil
  }
}
