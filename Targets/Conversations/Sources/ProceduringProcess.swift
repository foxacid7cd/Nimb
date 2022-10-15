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

public class ProceduringProcess: AsyncSequence {
  public typealias AsyncIterator = AsyncThrowingChannel<Element, Error>.AsyncIterator
  public typealias Element = MessageNotification

  public typealias Handler = (_ isSuccess: Bool, _ payload: MessagePackValue) async -> Void

  @MainActor
  private var process: MessagingProcess
  @MainActor
  private var handlers = [UInt: Handler]()
  @MainActor
  private var previousID: UInt?
  private let channel = AsyncThrowingChannel<MessageNotification, Error>()

  @MainActor
  public init(executableURL: URL, arguments: [String]) {
    process = .init(executableURL: executableURL, arguments: arguments)

    Task {
      for try await message in process {
        switch message {
        case let .request(id, method, parameters):
          channel.fail("unexpected request received, id \(id) method \(method) parameters: \(parameters)".fail())

        case let .response(id, isSuccess, payload):
          guard let handler = handlers[id] else {
            "handler for response with id \(id) is not registered".fail().failAssertion()
            continue
          }
          await handler(isSuccess, payload)

        case let .notification(notification):
          await channel.send(notification)
        }
      }
    }
  }

  @MainActor @discardableResult
  public func request(method: String, parameters: [MessagePackValue]) async throws -> MessagePackValue {
    try await withCheckedThrowingContinuation { continuation in
      let currentID = previousID.map { $0 + 1 } ?? 0

      self.registerHandler(id: currentID) { [weak self] isSuccess, payload in
        self?.unregisterHandler(id: currentID)

        isSuccess ? continuation.resume(returning: payload) : continuation.resume(throwing: payload)
      }

      do {
        try process.send(.request(id: currentID, method: method, parameters: parameters))
      } catch {
        continuation.resume(throwing: "failed sending request to process".fail(child: error.fail()))
      }

      self.previousID = currentID
    }
  }

  @MainActor
  public func makeAsyncIterator() -> AsyncIterator {
    channel.makeAsyncIterator()
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
