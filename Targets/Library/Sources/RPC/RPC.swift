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
    inputMessages: Observable<[Message]>
  ) {
    self.requestIDFactory = requestIDFactory

    let outputMessages = PublishSubject<[Message]>()
    self.outputMessages = outputMessages
    self.sendMessages = outputMessages.onNext(_:)

    self.inputResponses = inputMessages
      .map { messages in
        messages
          .compactMap { message in
            guard case let .response(id, model) = message else {
              return nil
            }

            return (id, model)
          }
      }
      .filter { !$0.isEmpty }

    self.notifications = inputMessages
      .map { messages in
        messages
          .compactMap { message in
            guard case let .notification(model) = message else {
              return nil
            }

            return model
          }
      }
      .filter { !$0.isEmpty }
  }

  public let outputMessages: Observable<[Message]>
  public let notifications: Observable<[Notification]>

  @MainActor @discardableResult
  public func request(_ model: Request) async -> Response {
    let id = self.requestIDFactory.makeRequestID()

    let response: Single<Response> = self.inputResponses
      .flatMap { inputResponses in
        for inputResponse in inputResponses where inputResponse.id == id {
          return Observable.just(inputResponse.model)
        }

        return .empty()
      }
      .replay(1)
      .asSingle()

    self.sendMessages([.request(id: id, model: model)])

    do {
      return try await response.value

    } catch {
      "awaiting for response message failed"
        .fail(child: error.fail())
        .assertionFailure()

      return .init(isSuccess: false, value: .nil)
    }
  }

  private var requestIDFactory: RequestIDFactory
  private let sendMessages: ([Message]) -> Void
  private let inputResponses: Observable<[(id: UInt, model: Response)]>
}
