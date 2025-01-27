// SPDX-License-Identifier: MIT

import CasePaths
import Foundation

@CasePathable
public enum Message: Sendable, Hashable {
  case request(Request)
  case response(Response)
  case notification(Notification)

  @PublicInit
  public struct Request: Sendable, Hashable {
    public static var rawMessageType: Int {
      0
    }

    public var id: Int
    public var method: String
    public var parameters: [Value]

    init(arrayValue: [Value]) throws {
      guard
        arrayValue.count == 4,
        case let .integer(id) = arrayValue[1],
        case let .string(method) = arrayValue[2],
        case let .array(parameters) = arrayValue[3]
      else {
        throw Failure("Invalid request raw array value \(arrayValue)")
      }

      self.init(
        id: id,
        method: method,
        parameters: parameters
      )
    }

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
    public enum Result: Sendable, Hashable {
      case success(Value)
      case failure(Value)

      public func map<Success>(
        _ successBody: (Value) throws -> Success,
        _ failureBody: (Value) -> any Error
      ) throws
        -> Success
      {
        switch self {
        case let .success(value):
          return try successBody(value)

        case let .failure(error):
          throw failureBody(error)
        }
      }
    }

    public static var rawMessageType: Int {
      1
    }

    public var id: Int
    public var result: Result

    init(arrayValue: [Value]) throws {
      guard
        arrayValue.count == 4,
        case let .integer(id) = arrayValue[1]
      else {
        throw Failure("Invalid response raw array value \(arrayValue)")
      }

      let result: Result =
        if arrayValue[2] != .nil {
          .failure(arrayValue[2])

        } else {
          .success(arrayValue[3])
        }

      self.init(id: id, result: result)
    }
  }

  @PublicInit
  public struct Notification: Sendable, Hashable {
    public static var rawMessageType: Int {
      2
    }

    public var method: String
    public var parameters: [Value]

    init(arrayValue: [Value]) throws {
      guard
        arrayValue.count == 3,
        case let .string(method) = arrayValue[1],
        case let .array(parameters) = arrayValue[2]
      else {
        throw Failure("Invalid notification raw array value \(arrayValue)")
      }

      self.init(method: method, parameters: parameters)
    }
  }

  public init(value: Value) throws {
    guard case let .array(arrayValue) = value, !arrayValue.isEmpty else {
      throw Failure("Invalid message raw value \(value)")
    }
    guard case let .integer(rawMessageType) = arrayValue[0] else {
      throw Failure("Unknown raw message type value \(arrayValue[0])")
    }
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
      throw Failure("Unknown raw message type value \(arrayValue[0])")
    }
  }
}
