// SPDX-License-Identifier: MIT

import CasePaths
import Library

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
      self = try .request(
        Request(arrayValue: arrayValue)
      )

    case Response.rawMessageType:
      self = try .response(
        Response(arrayValue: arrayValue)
      )

    case Notification.rawMessageType:
      self = try .notification(
        Notification(arrayValue: arrayValue)
      )

    default:
      throw Failure("Unknown raw message type \(arrayValue[0])")
    }
  }

  @PublicInit
  public struct Request: Sendable, Hashable {
    init(arrayValue: [Value]) throws {
      guard
        arrayValue.count == 4,
        let id = (/Value.integer)
          .extract(from: arrayValue[1]),
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

    public static var rawMessageType: Int {
      0
    }

    public var id: Int
    public var method: String
    public var parameters: [Value]

    func makeValue() -> Value {
      .array([
        .integer(Self.rawMessageType),
        .integer(id),
        .string(method),
        .array(parameters),
      ])
    }
  }

  @PublicInit
  public struct Response: Sendable, Hashable {
    init(arrayValue: [Value]) throws {
      guard
        arrayValue.count == 4,
        let id = (/Value.integer).extract(from: arrayValue[1])
      else {
        throw Failure("Invalid response raw array value \(arrayValue)")
      }

      let result: Result = if arrayValue[2] != .nil {
        .failure(arrayValue[2])

      } else {
        .success(arrayValue[3])
      }

      self.init(id: id, result: result)
    }

    public enum Result: Sendable, Hashable {
      case success(Value)
      case failure(Value)

      public func map<Success>(_ successBody: (Value) throws -> Success, _ failureBody: (Value) -> any Error) throws -> Success {
        switch self {
        case let .success(value):
          return try successBody(value)

        case let .failure(error):
          throw failureBody(error)
        }
      }

      public func map<Success>(_ casePath: AnyCasePath<Value, Success>) throws -> Success {
        switch self {
        case let .success(value):
          guard let value = casePath.extract(from: value) else {
            throw Failure("Unexpected type of value", value)
          }
          return value

        case let .failure(error):
          throw Failure("Neovim error", error)
        }
      }
    }

    public static var rawMessageType: Int {
      1
    }

    public var id: Int
    public var result: Result
  }

  @PublicInit
  public struct Notification: Sendable, Hashable {
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

    public static var rawMessageType: Int {
      2
    }

    public var method: String
    public var parameters: [Value]
  }
}
