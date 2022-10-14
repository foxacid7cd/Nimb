//
//  Message.swift
//
//
//  Created by Yevhenii Matviienko on 28.09.2022.
//

import Library
import MessagePack

public enum Message {
  case request(id: UInt, method: Method)
  case response(id: UInt, isSuccess: Bool, payload: MessagePackValue)
  case notification(method: Method)

  public init(messagePackValue: MessagePackValue) throws {
    switch messagePackValue {
    case var .array(array):
      var message: Message

      guard !array.isEmpty, let messageTypeCode = array.removeFirst().uintValue.flatMap(MessageTypeCode.init) else {
        throw "Could not unpack message type code."
      }
      switch messageTypeCode {
      case .request:
        guard !array.isEmpty, let id = array.removeFirst().uintValue else {
          throw "Could not unpack request messsage id"
        }
        guard !array.isEmpty, let method = array.removeFirst().stringValue else {
          throw "Could not unpack request message method"
        }
        let params: [MessagePackValue]? = {
          guard !array.isEmpty else { return nil }
          let value = array.removeFirst()
          if value.isNil {
            return []
          } else if let params = value.arrayValue {
            return params
          } else {
            return nil
          }
        }()
        guard let params else {
          throw "Could not unpack request message method params"
        }
        message = .request(id: id, method: .init(name: method, parameters: params))

      case .response:
        guard !array.isEmpty, let id = array.removeFirst().uintValue else {
          throw "Could not unpack response messsage id"
        }
        guard !array.isEmpty else {
          throw "Could not unpack response error message element"
        }
        let errorValue = array.removeFirst()
        guard !array.isEmpty else {
          throw "Could not unpack response result message element"
        }
        let resultValue = array.removeFirst()

        let isSuccess: Bool
        let payload: MessagePackValue
        if errorValue.isNil {
          isSuccess = true
          payload = resultValue
        } else {
          isSuccess = false
          payload = errorValue
        }
        message = .response(id: id, isSuccess: isSuccess, payload: payload)

      case .notification:
        guard !array.isEmpty, let method = array.removeFirst().stringValue else {
          throw "Could not unpack notification message method"
        }
        let params: [MessagePackValue]? = {
          guard !array.isEmpty else {
            return nil
          }
          let value = array.removeFirst()
          if value.isNil {
            return []
          } else if let params = value.arrayValue {
            return params
          } else {
            return nil
          }
        }()
        guard let params else {
          throw "Could not unpack notification message params"
        }
        message = .notification(method: .init(name: method, parameters: params))
      }

      guard array.isEmpty else {
        throw "Too much elements in root array"
      }
      self = message

    default:
      throw "Root packed value is not an array."
    }
  }

  public var messagePackValue: MessagePackValue {
    let array: [MessagePackValue]

    switch self {
    case let .request(id, method):
      array = [
        .uint(UInt64(MessageTypeCode.request.rawValue)),
        .uint(UInt64(id)),
        .string(method.name),
        .array(method.parameters),
      ]

    case let .response(id, isSuccess, payload):
      array = [
        .uint(UInt64(MessageTypeCode.response.rawValue)),
        .uint(UInt64(id)),
        isSuccess ? .nil : payload,
        isSuccess ? payload : .nil,
      ]

    case let .notification(method):
      array = [
        .uint(UInt64(MessageTypeCode.notification.rawValue)),
        .string(method.name),
        .array(method.parameters),
      ]
    }

    return .array(array)
  }
}

public enum MessageTypeCode: UInt {
  case request = 0, response, notification
}
