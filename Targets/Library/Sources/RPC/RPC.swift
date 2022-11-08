//
//  RPC.swift
//  Library
//
//  Created by Yevhenii Matviienko on 16.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AsyncAlgorithms
import Foundation
import RxSwift

public class RPC {
  public init() {
    let notificationsChannel = AsyncChannel<[Notification]>()
    self.notifications = notificationsChannel.eraseToAnyAsyncSequence()

    Task {
      var notificationsBuffer = [Notification]()

      for await inputMessages in inputMessagesChannel {
        for inputMessage in inputMessages {
          switch inputMessage {
          case let .response(id, model):
            if let handler = await self.unregisterInputResponseHandler(requestID: id) {
              handler(model)
            }

          case let .notification(model):
            notificationsBuffer.append(model)

          case .request:
            break
          }
        }

        if !notificationsBuffer.isEmpty {
          await notificationsChannel.send(notificationsBuffer)

          notificationsBuffer.removeAll(keepingCapacity: true)
        }
      }
    }
  }

  public let notifications: AnyAsyncSequence<[Notification]>

  public var outputMessages: AnyAsyncSequence<[Message]> {
    self.outputMessagesChannel
      .eraseToAnyAsyncSequence()
  }

  @discardableResult
  public func request(_ model: Request) async -> Response {
    let id = await self.stepper.next()

    let channel = AsyncChannel<Response>()

    await self.register(
      inputResponseHandler: { response in
        Task { await channel.send(response) }
      },
      requestID: id
    )

    Task {
      await self.outputMessagesChannel.send(
        [.request(id: id, model: model)]
      )
    }

    for await response in channel {
      return response
    }

    "Request without response"
      .fail()
      .fatalError()
  }

  public func send(inputMessages: [Message]) async {
    await self.inputMessagesChannel.send(inputMessages)
  }

  private let stepper = Stepper()
  @MainActor
  private var inputResponseHandlers = [UInt: @Sendable (Response) -> Void]()
  private let inputMessagesChannel = AsyncChannel<[Message]>()
  private let outputMessagesChannel = AsyncChannel<[Message]>()

  @MainActor
  private func register(inputResponseHandler: (@Sendable (Response) -> Void)?, requestID: UInt) {
    if let inputResponseHandler {
      self.inputResponseHandlers[requestID] = inputResponseHandler

    } else {
      self.inputResponseHandlers.removeValue(forKey: requestID)
    }
  }

  @MainActor
  private func unregisterInputResponseHandler(requestID: UInt) -> (@Sendable (Response) -> Void)? {
    self.inputResponseHandlers.removeValue(forKey: requestID)
  }
}
