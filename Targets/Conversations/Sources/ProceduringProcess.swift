//
//  ProceduringProcess.swift
//  Procedures
//
//  Created by Yevhenii Matviienko on 13.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AsyncAlgorithms
import Foundation
import Library
import MessagePack

@ProcessActor
public class ProceduringProcess: AsyncSequence {
  public init(executableURL: URL, arguments: [String]) {
    let process = MessagingProcess(executableURL: executableURL, arguments: arguments)
    self.process = process

    Task {
      do {
        for try await message in process {
          switch message {
          case let .request(id, method, parameters):
            self.channel.fail("unexpected request received, id \(id) method \(method) parameters: \(parameters)".fail())

          case let .response(id, isSuccess, payload):
            guard let handler = self.handlers[id] else {
              "handler for response with id \(id) is not registered".fail().failAssertion()
              continue
            }
            await handler(isSuccess, payload)

          case let .notification(notification):
            await self.channel.send(notification)
          }
        }
      } catch {
        "receiving messages failed".fail(child: error.fail()).failAssertion()
      }
    }
  }

  public typealias AsyncIterator = AsyncThrowingChannel<Element, Error>.AsyncIterator
  public typealias Element = MessageNotification

  public typealias Handler = (_ isSuccess: Bool, _ payload: MessagePackValue) async -> Void

  @discardableResult
  public func request(method: String, parameters: [MessagePackValue]) async throws -> MessagePackValue {
    try await withCheckedThrowingContinuation { continuation in
      let currentID = previousID.map { $0 + 1 } ?? 0
      self.previousID = currentID

      self.registerHandler(id: currentID) { isSuccess, payload in
        self.unregisterHandler(id: currentID)

        isSuccess ? continuation.resume(returning: payload) : continuation.resume(throwing: payload)
      }

      do {
        try process.send(.request(id: currentID, method: method, parameters: parameters))
      } catch {
        continuation.resume(throwing: "failed sending request to process".fail(child: error.fail()))
      }
    }
  }

  public nonisolated func makeAsyncIterator() -> AsyncIterator {
    self.channel.makeAsyncIterator()
  }

  private var process: MessagingProcess
  private var handlers = [UInt: Handler]()
  private var previousID: UInt?
  private let channel = AsyncThrowingChannel<MessageNotification, Error>()
  
  private func nextMessageID() -> Message {
    
  }

  private func registerHandler(id: UInt, handler: @escaping Handler) {
    self.handlers[id] = handler
  }

  private func unregisterHandler(id: UInt) {
    self.handlers[id] = nil
  }
}
