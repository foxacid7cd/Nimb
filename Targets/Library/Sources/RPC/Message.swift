//
//  Message.swift
//  Library
//
//  Created by Yevhenii Matviienko on 16.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

public enum Message {
  case request(id: UInt, model: Request)
  case response(id: UInt, model: Response)
  case notification(Notification)

  public init(value: Value) throws {
    guard let arrayValue = value.arrayValue else {
      throw "message expected to be created from array value".fail()
    }

    var previousPosition: Int?
    func next<ReturnType>(
      _ entity: String,
      _ transform: (Value) -> ReturnType? = { $0 },
      file: StaticString = #fileID,
      line: UInt = #line
    ) throws -> ReturnType {
      let currentPosition = previousPosition.map { $0 + 1 } ?? 0
      defer { previousPosition = currentPosition }

      guard arrayValue.count > currentPosition, let value = transform(arrayValue[currentPosition]) else {
        throw "element at index \(currentPosition) is expected to be \(entity)".fail(file: file, line: line)
      }

      return value
    }

    func finalize(_ entity: String, file: StaticString = #fileID, line: UInt = #line) throws {
      guard let previousPosition, previousPosition == arrayValue.count - 1 else {
        throw "\(entity) is expected to be created from \(previousPosition.map { $0 + 1 } ?? 0) elements, but \(arrayValue.count) elements were passed"
          .fail(file: file, line: line)
      }
    }

    let messageType = try next("unsigned integer representing message type") { $0.uintValue.flatMap(MessageType.init) }

    switch messageType {
    case .request:
      let id = try next("unsigned integer representing request id") { $0.uintValue }
      let method = try next("string representing request method") { $0.stringValue }
      let parameters = try next("array of request parameters") { $0.arrayValue }
      try finalize("request message")
      self = .request(id: id, model: .init(method: method, parameters: parameters))

    case .response:
      let id = try next("unsiged integer representing response id") { $0.uintValue }
      let failure = try next("value representing payload for response on failed request")
      let success = try next("value representing payload for response on succeeded request")
      try finalize("response message")
      self = .response(id: id, model: .init(isSuccess: failure.isNil, value: failure.isNil ? failure : success))

    case .notification:
      let method = try next("string representing notification method") { $0.stringValue }
      let parameters = try next("array representing notification parameters") { $0.arrayValue }
      try finalize("notification message")
      self = .notification(.init(method: method, parameters: parameters.normalizedToParametersArray))
    }
  }

  public var value: Value {
    let arrayValue: [Value]

    switch self {
    case let .request(id, model):
      arrayValue = [
        .uint(UInt64(MessageType.request.rawValue)),
        .uint(UInt64(id)),
        .string(model.method),
        .array(model.parameters)
      ]

    case let .response(id, model):
      arrayValue = [
        .uint(UInt64(MessageType.response.rawValue)),
        .uint(UInt64(id)),
        model.isSuccess ? .nil : model.value,
        model.isSuccess ? model.value : .nil
      ]

    case let .notification(notification):
      arrayValue = [
        .uint(UInt64(MessageType.notification.rawValue)),
        .string(notification.method),
        .array(notification.parameters.map(Value.array))
      ]
    }

    return .array(arrayValue)
  }
}
