//
//  RPC.swift
//  Library
//
//  Created by Yevhenii Matviienko on 16.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation
import RxSwift

public class RPC {
  public init(
    requestIDFactory: RequestIDFactory = Stepper(),
    inputMessages: Observable<Message>
  ) {
    self.requestIDFactory = requestIDFactory

    let outputMessages = PublishSubject<Message>()
    self.outputMessages = outputMessages
    self.sendMessage = outputMessages.onNext(_:)

    self.inputResponses = inputMessages
      .compactMap { message in
        guard case let .response(id, model) = message else {
          return nil
        }

        return (id, model)
      }

    self.notifications = inputMessages
      .compactMap { message in
        guard case let .notification(model) = message else {
          return nil
        }

        return model
      }
  }

  public let outputMessages: Observable<Message>
  public let notifications: Observable<Notification>

  @MainActor @discardableResult
  public func request(_ model: Request) async -> Response {
    let id = self.requestIDFactory.makeRequestID()

    let response: Single<Response> = self.inputResponses
      .filter { $0.id == id }
      .map { $0.model }
      .replay(1)
      .asSingle()

    self.sendMessage(.request(id: id, model: model))

    do {
      return try await response.value

    } catch {
      "awaiting for response message failed"
        .fail(child: error.fail())
        .fatal()
    }
  }

  private var requestIDFactory: RequestIDFactory
  private let sendMessage: (Message) -> Void
  private let inputResponses: Observable<(id: UInt, model: Response)>
}
