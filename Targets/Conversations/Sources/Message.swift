//
//  Message.swift
//
//
//  Created by Yevhenii Matviienko on 28.09.2022.
//

import Library
import MessagePack

public enum Message {
  case request(id: UInt, method: String, parameters: [MessagePackValue])
  case response(id: UInt, isSuccess: Bool, payload: MessagePackValue)
  case notification(MessageNotification)

  public init?(messagePackValue: MessagePackValue) {
    guard let arrayValue = messagePackValue.arrayValue else {
      assertionFailure("message expected to be created from array value")
      return nil
    }

    var previousPosition: Int?
    func next<ValueType>(_ entity: String, _ transform: (MessagePackValue) -> ValueType? = { $0 }, file: StaticString = #file, line: UInt = #line) -> ValueType? {
      let currentPosition = previousPosition.map { $0 + 1 } ?? 0
      defer { previousPosition = currentPosition }

      guard arrayValue.count > currentPosition, let value = transform(arrayValue[currentPosition]) else {
        assertionFailure("element at index \(currentPosition) is expected to be \(entity)", file: file, line: line)
        return nil
      }

      return value
    }

    func finalize(_ entity: String, file: StaticString = #file, line: UInt = #line) -> Bool {
      guard let previousPosition, previousPosition == arrayValue.count - 1 else {
        assertionFailure("\(entity) is expected to be created from \(previousPosition.map { $0 + 1 } ?? 0) elements, but \(arrayValue.count) elements were passed", file: file, line: line)
        return false
      }

      return true
    }

    guard let messageType = next("unsigned integer representing message type", { $0.uintValue.flatMap(MessageType.init) }) else {
      return nil
    }
    switch messageType {
    case .request:
      guard
        let id = next("unsigned integer representing request id", { $0.uintValue }),
        let method = next("string representing request method", { $0.stringValue }),
        let parameters = next("array of request parameters", { $0.arrayValue }),
        finalize("request message")
      else {
        return nil
      }

      self = .request(id: id, method: method, parameters: parameters)

    case .response:
      guard
        let id = next("unsiged integer representing response id", { $0.uintValue }),
        let failure = next("value representing payload for response on failed request"),
        let success = next("value representing payload for response on succeeded request"),
        finalize("response message")
      else {
        return nil
      }

      self = .response(id: id, isSuccess: failure.isNil, payload: failure.isNil ? success : failure)

    case .notification:
      guard
        let method = next("string representing notification method", { $0.stringValue }),
        let parameters = next("array representing notification parameters", { $0.arrayValue }),
        finalize("notification message")
      else {
        return nil
      }

      self = .notification(.init(method: method, parametersArray: parameters.normalizedToParametersArray))
    }
  }

  public var messagePackValue: MessagePackValue {
    let arrayValue: [MessagePackValue]

    switch self {
    case let .request(id, method, parameters):
      arrayValue = [
        .uint(UInt64(MessageType.request.rawValue)),
        .uint(UInt64(id)),
        .string(method),
        .array(parameters),
      ]

    case let .response(id, isSuccess, payload):
      arrayValue = [
        .uint(UInt64(MessageType.response.rawValue)),
        .uint(UInt64(id)),
        isSuccess ? .nil : payload,
        isSuccess ? payload : .nil,
      ]

    case let .notification(notification):
      let parametersArrayValue: [MessagePackValue] = {
        if notification.parametersArray.count == 1 {
          return notification.parametersArray[0]
        } else {
          return notification.parametersArray
            .map(MessagePackValue.array)
        }
      }()

      arrayValue = [
        .uint(UInt64(MessageType.notification.rawValue)),
        .string(notification.method),
        .array(parametersArrayValue),
      ]
    }

    return .array(arrayValue)
  }
}
