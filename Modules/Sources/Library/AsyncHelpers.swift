// Copyright © 2022 foxacid7cd. All rights reserved.

import AsyncAlgorithms
import Foundation

extension AsyncStream {
  public init<S: AsyncSequence>(
    _ sequence: S,
    bufferingPolicy: Continuation.BufferingPolicy = .unbounded
  ) where S.Element == Element {
    self.init(Element.self, bufferingPolicy: bufferingPolicy) { continuation in
      let task = Task {
        do {
          for try await element in sequence {
            if Task.isCancelled { break }

            continuation.yield(element)
          }
        } catch {
          preconditionFailure("Please use AsyncThrowingStream for wrapping throwing sequences.")
        }

        continuation.finish()
      }

      continuation.onTermination = { termination in
        switch termination {
        case .cancelled: task.cancel()

        default: return
        }
      }
    }
  }
}

extension AsyncThrowingStream where Failure == Error {
  public init<S: AsyncSequence>(
    _ sequence: S,
    bufferingPolicy _: Continuation.BufferingPolicy = .unbounded
  ) where S.Element == Element {
    self.init(Element.self, bufferingPolicy: .unbounded) { continuation in
      let task = Task {
        for try await element in sequence {
          if Task.isCancelled { break }

          continuation.yield(element)
        }

        continuation.finish()
      }

      continuation.onTermination = { termination in
        switch termination {
        case .cancelled: task.cancel()

        default: return
        }
      }
    }
  }
}

extension AsyncSequence {
  public var erasedToAsyncStream: AsyncStream<Element> { .init(self) }

  public var erasedToAsyncThrowingStream: AsyncThrowingStream<Element, Error> { .init(self) }
}

extension AsyncChannel {
  public static func pipe(
    bufferingPolicy: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded
  ) -> (send: @Sendable (Element) async -> Void, stream: AsyncStream<Element>) {
    let channel = AsyncChannel<Element>()

    return (
      send: { await channel.send($0) }, stream: .init(channel, bufferingPolicy: bufferingPolicy)
    )
  }
}

extension AsyncThrowingChannel where Failure == Error {
  public static func pipe<Element>(
    bufferingPolicy: AsyncThrowingStream<Element, Failure>.Continuation.BufferingPolicy = .unbounded
  ) -> (send: @Sendable (Element) async -> Void, stream: AsyncThrowingStream<Element, Failure>) {
    let channel = AsyncThrowingChannel<Element, Failure>()

    return (
      send: { await channel.send($0) }, stream: .init(channel, bufferingPolicy: bufferingPolicy)
    )
  }
}

extension FileHandle {
  public var dataBatches: AsyncStream<Data> {
    .init { continuation in
      readabilityHandler = { fileHandle in let data = fileHandle.availableData

        if data.isEmpty {
          continuation.finish()

        } else {
          continuation.yield(data)
        }
      }

      continuation.onTermination = { _ in self.readabilityHandler = nil }
    }
  }
}