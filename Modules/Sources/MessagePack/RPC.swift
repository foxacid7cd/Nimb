// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import CasePaths
import Collections
import Foundation
import Library
import Tagged
import CustomDump

public struct RPC<Target: Channel>: AsyncSequence, Sendable {
  public init(target: Target) {
    self.target = target
    self.messageBatches = .init(dataBatches: target.dataBatches)
  }

  public var target: Target

  private let packer = Packer()
  private let store = Store()
  private let messageBatches: AsyncMessageBatches<Target.S>

  public typealias Element = [Notification]

  public func makeAsyncIterator() -> AsyncIterator {
    .init(
      store: store,
      messageBatchesIterator: messageBatches.makeAsyncIterator()
    )
  }

  public struct AsyncIterator: AsyncIteratorProtocol {
    let store: Store
    var messageBatchesIterator: AsyncMessageBatches<Target.S>.AsyncIterator

    public mutating func next() async throws -> [Notification]? {
      var accumulator = [Notification]()

      while true {
        guard let messages = try await messageBatchesIterator.next() else {
          return nil
        }

        try Task.checkCancellation()

        for message in messages {
          switch message {
          case let .request(request):
            assertionFailure("Unexpected request message: \(request)")

          case let .response(response):
            await store.responseReceived(
              response,
              forRequestWithID: .init(
                rawValue: response.id.rawValue
              )
            )

          case let .notification(notification):
            accumulator.append(notification)
          }
        }

        if !accumulator.isEmpty {
          return accumulator
        }
      }
    }
  }

  @discardableResult
  public func call(
    method: String,
    withParameters parameters: [Value]
  ) async throws -> Response.Result {
    await withUnsafeContinuation { continuation in
      Task {
        try await send(
          request: .init(
            id: await store.announceRequest {
              continuation.resume(returning: $0.result)
            },
            method: method,
            parameters: parameters
          ))
      }
    }
  }

  public func fastCall(method: String, withParameters parameters: [Value]) async throws {
    try await send(
      request: .init(
        id: await store.announceRequest(),
        method: method,
        parameters: parameters
      )
    )
  }

  public func send(request: Request) async throws {
    let data = await packer.pack(
      request.makeValue()
    )
    try await target.write(data)
  }

  actor Store {
    func announceRequest(_ handler: (@Sendable (Response) -> Void)? = nil) -> Request.ID {
      let id = Request.ID(announcedRequestsCount)
      announcedRequestsCount += 1

      if let handler {
        currentRequests[id] = handler
      }
      return id
    }

    func responseReceived(_ response: Response, forRequestWithID id: Request.ID) {
      guard let handler = currentRequests.removeValue(forKey: id) else {
        return
      }

      handler(response)
    }

    private var announcedRequestsCount = 0
    private var currentRequests = TreeDictionary < Request.ID, @Sendable (Response) -> Void > ()
  }

  private enum MessageType: Int {
    case request = 0
    case response
    case notification
  }

  public enum ParsingFailed: Error {
    case messageType(rawMessage: Value)
    case request(rawRequest: [Value])
    case response(rawResponse: [Value])
    case notification(rawNotification: [Value])
  }

  public struct RemoteError: Error, Hashable {
    public var value: Value
  }

  public enum Message: Sendable, Hashable {
    case request(Request)
    case response(Response)
    case notification(Notification)

    init(value: Value) throws {
      guard
        let arrayValue = (/Value.array).extract(from: value),
        !arrayValue.isEmpty,
        let integer = (/Value.integer).extract(from: arrayValue[0]),
        let messageType = MessageType(rawValue: integer)
      else {
        throw ParsingFailed.messageType(rawMessage: value)
      }

      switch messageType {
      case .request:
        self = .request(
          try Request(arrayValue: arrayValue)
        )

      case .response:
        self = .response(
          try Response(arrayValue: arrayValue)
        )

      case .notification:
        self = .notification(
          try Notification(arrayValue: arrayValue)
        )
      }
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

    func makeValue() -> Value {
      .array([
        .integer(MessageType.request.rawValue),
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
        throw ParsingFailed.request(rawRequest: arrayValue)
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

    public enum Result: Sendable, Hashable {
      case success(Value)
      case failure(RemoteError)
    }

    init(arrayValue: [Value]) throws {
      guard
        arrayValue.count == 4,
        let id = (/Value.integer)
          .extract(from: arrayValue[1])
          .map(Response.ID.init(rawValue:))
      else {
        throw ParsingFailed.response(rawResponse: arrayValue)
      }

      let result: Result
      if arrayValue[2] != .nil {
        result = .failure(.init(value: arrayValue[2]))

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

    init(arrayValue: [Value]) throws {
      guard
        arrayValue.count == 3,
        let method = (/Value.string).extract(from: arrayValue[1]),
        let parameters = (/Value.array).extract(from: arrayValue[2])
      else {
        throw ParsingFailed.notification(rawNotification: arrayValue)
      }

      self.init(method: method, parameters: parameters)
    }
  }

  struct AsyncMessageBatches<DataBatches: AsyncSequence>: AsyncSequence, Sendable where DataBatches.Element == Data, DataBatches: Sendable {
    var dataBatches: DataBatches

    private let unpacker: Unpacker = .init()

    typealias Element = [Message]

    func makeAsyncIterator() -> AsyncIterator {
      .init(
        unpacker: unpacker,
        dataBatchesIterator: dataBatches.makeAsyncIterator()
      )
    }

    struct AsyncIterator: AsyncIteratorProtocol {
      let unpacker: Unpacker
      var dataBatchesIterator: DataBatches.AsyncIterator

      typealias Element = [Message]

      mutating func next() async throws -> [Message]? {
        guard let data = try await dataBatchesIterator.next() else {
          return nil
        }

        try Task.checkCancellation()

        return try await unpacker.unpack(data)
          .map(Message.init(value:))
      }
    }
  }
}
