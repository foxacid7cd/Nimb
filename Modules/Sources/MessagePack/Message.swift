// SPDX-License-Identifier: MIT

import CasePaths
import Library
import Tagged

public enum Message: Sendable, Hashable {
  case request(Request)
  case response(Response)
  case notification(Notification)

  init(value: Value) throws {
    guard let arrayValue = (/Value.array).extract(from: value), !arrayValue.isEmpty else {
      throw Failure("Invalid message raw value \(value)")
    }

    let rawMessageType = (/Value.integer).extract(from: arrayValue[0])
    switch rawMessageType {
    case Request.rawMessageType:
      self = .request(
        try Request(arrayValue: arrayValue)
      )

    case Response.rawMessageType:
      self = .response(
        try Response(arrayValue: arrayValue)
      )

    case Notification.rawMessageType:
      self = .notification(
        try Notification(arrayValue: arrayValue)
      )

    default:
      throw Failure("Unknown raw message type \(arrayValue[0])")
    }
  }

  public struct Request: Sendable, Hashable {
    public init(id: ID, method: String, parameters: [Value]) {
      self.id = id
      self.method = method
      self.parameters = parameters
    }

    public var id: ID
    public var method: String
    public var parameters: [Value]

    public typealias ID = Tagged<Self, Int>

    public static var rawMessageType: Int {
      0
    }

    func makeValue() -> Value {
      .array([
        .integer(Self.rawMessageType),
        .integer(id.rawValue),
        .string(method),
        .array(parameters),
      ])
    }

    init(arrayValue: [Value]) throws {
      guard
        arrayValue.count == 4,
        let id = (/Value.integer)
          .extract(from: arrayValue[1])
          .map(ID.init(rawValue:)),
        let method = (/Value.string).extract(from: arrayValue[2]),
        let parameters = (/Value.array).extract(from: arrayValue[3])
      else {
        throw Failure("Invalid request raw array value \(arrayValue)")
      }

      self.init(
        id: id,
        method: method,
        parameters: parameters
      )
    }
  }

  public struct Response: Sendable, Hashable {
    public init(id: ID, result: Result) {
      self.id = id
      self.result = result
    }

    public var id: ID
    public var result: Result

    public typealias ID = Tagged<Self, Int>

    public static var rawMessageType: Int {
      1
    }

    public enum Result: Sendable, Hashable {
      case success(Value)
      case failure(Value)
    }

    init(arrayValue: [Value]) throws {
      guard
        arrayValue.count == 4,
        let id = (/Value.integer)
          .extract(from: arrayValue[1])
          .map(Response.ID.init(rawValue:))
      else {
        throw Failure("Invalid response raw array value \(arrayValue)")
      }

      let result: Result
      if arrayValue[2] != .nil {
        result = .failure(arrayValue[2])

      } else {
        result = .success(arrayValue[3])
      }

      self.init(id: id, result: result)
    }
  }

  public struct Notification: Sendable, Hashable {
    public init(method: String, parameters: [Value]) {
      self.method = method
      self.parameters = parameters
    }

    public var method: String
    public var parameters: [Value]

    public static var rawMessageType: Int {
      2
    }

    init(arrayValue: [Value]) throws {
      guard
        arrayValue.count == 3,
        let method = (/Value.string).extract(from: arrayValue[1]),
        let parameters = (/Value.array).extract(from: arrayValue[2])
      else {
        throw Failure("Invalid notification raw array value \(arrayValue)")
      }

      self.init(method: method, parameters: parameters)
    }
  }
}
