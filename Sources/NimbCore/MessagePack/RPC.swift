// SPDX-License-Identifier: MIT

import Algorithms
import Collections
import Combine
import CustomDump
import Foundation
import msgpack_c
import Synchronization

public final class RPC: Sendable {
  public let notifications: AsyncThrowingStream<[Message.Notification], any Error>

  private let target: Mutex<any Channel>
  /// Channels the reader should work through, in order. `:restart` hands over
  /// a new server to attach to, so the transport outlives any one channel.
  private let targetsContinuation: AsyncStream<any Channel>.Continuation
  private let storage = Storage()
  private let packer = Mutex<Packer>(.init())

  public init(_ target: any Channel) {
    self.target = .init(target)

    let (targets, targetsContinuation) = AsyncStream<any Channel>.makeStream()
    self.targetsContinuation = targetsContinuation
    targetsContinuation.yield(target)

    notifications = AsyncThrowingStream<[Message.Notification], any Error> { [storage] continuation in
      Task {
        await Self.read(from: targets, into: storage, yieldingTo: continuation)
      }
    }
  }

  /// The msgpack reader loop. @concurrent rather than a bare `Task { }`, which
  /// would inherit the main actor from where RPC.init is reached.
  @concurrent
  private static func read(
    from targets: AsyncStream<any Channel>,
    into storage: Storage,
    yieldingTo continuation: AsyncThrowingStream<[Message.Notification], any Error>.Continuation,
  ) async {
    for await target in targets {
      // A fresh unpacker per channel: a new server starts a new msgpack
      // stream, and half a message from the old one must not lead into it.
      await read(from: target, into: storage, yieldingTo: continuation)
      guard !Task.isCancelled else {
        break
      }
    }
  }

  private static func read(
    from target: any Channel,
    into storage: Storage,
    yieldingTo continuation: AsyncThrowingStream<[Message.Notification], any Error>.Continuation,
  ) async {
    do {
      var notifications = [Message.Notification]()

      let unpacker = Unpacker()

      for try await data in target.dataBatches {
        guard !Task.isCancelled else {
          break
        }

        let messages = try unpacker.unpack(data)
          .map { try Message(value: $0) }

        for message in messages {
          switch message {
          case let .request(request):
            logger.warning("Unexpected msgpack request received: \(String(customDumping: request))")

          case let .response(response):
            storage.responseReceived(response, forRequestWithID: response.id)

          case let .notification(notification):
            notifications.append(notification)
          }
        }

        if !notifications.isEmpty {
          continuation.yield(notifications)
          notifications.removeAll(keepingCapacity: true)
        }
      }

    } catch {
      continuation.finish(throwing: error)
    }
  }

  /// Points reads and writes at a new server. The notifications stream carries
  /// on across the swap, so everything built on top of this RPC survives it.
  public func reconnect(to newTarget: any Channel) {
    target.withLock { $0 = newTarget }
    targetsContinuation.yield(newTarget)
  }

  @discardableResult
  public func call(
    method: String,
    withParameters parameters: [Value],
  ) async
  -> Message.Response.Result {
    await withCheckedContinuation { continuation in
      send(request: .init(
        id: storage.announceRequest {
          continuation.resume(returning: $0.result)
        },
        method: method,
        parameters: parameters,
      ))
    }
  }

  /// Sends on the caller's thread, in call order. Neovim applies input in the
  /// order it arrives, and the write is one blocking syscall on a pipe.
  public func fastCall(
    method: String,
    withParameters parameters: [Value],
  ) {
    send(request: .init(
      id: storage.announceRequest(),
      method: method,
      parameters: parameters,
    ))
  }

  /// Packs several calls into one write. Ordering is already guaranteed by
  /// fastCall, so this exists only to spend one syscall instead of N.
  public func fastCallsTransaction(with calls: some Sequence<(
    method: String,
    parameters: [Value],
  )> & Sendable) {
    let data = packer.withLock { packer in
      var data = Data()
      for call in calls {
        let message = Message.Request(
          id: storage.announceRequest(),
          method: call.method,
          parameters: call.parameters,
        )
        data.append(packer.pack(message.makeValue()))
      }
      return data
    }

    write(data)
  }

  public func send(request: Message.Request) {
    let data = packer.withLock {
      $0.pack(request.makeValue())
    }

    write(data)
  }

  /// Writes under the target's own lock, which serialises them: a pipe only
  /// makes a write atomic up to PIPE_BUF, 512 bytes here, so two unserialised
  /// writers can interleave a larger message into a stream Neovim cannot
  /// parse. Separate from `packer`, so packing does not queue behind a write.
  private func write(_ data: Data) {
    try? target.withLock { try $0.write(data) }
  }
}

/// Lock rather than actor isolation, so allocating a request id is a plain
/// synchronous call and sends need no task that could race another to the pipe.
private final class Storage: Sendable {
  private struct State {
    var currentRequests = IntKeyedDictionary<@Sendable (Message.Response) -> Void>()
    var announcedRequestsCount = 0
  }

  private let state = Mutex(State())

  func announceRequest(
    _ handler: (@Sendable (Message.Response) -> Void)? = nil,
  )
    -> Int
  {
    state.withLock { state in
      let id = state.announcedRequestsCount
      state.announcedRequestsCount &+= 1
      if let handler {
        state.currentRequests[id] = handler
      }
      return id
    }
  }

  func responseReceived(
    _ response: Message.Response,
    forRequestWithID id: Int,
  ) {
    // Taken under the lock, invoked outside it: the handler resumes a
    // continuation, and what that wakes must not run while the lock is held.
    let handler = state.withLock { state -> (@Sendable (Message.Response) -> Void)? in
      let handler = state.currentRequests[id]
      state.currentRequests[id] = nil
      return handler
    }
    handler?(response)
  }
}
