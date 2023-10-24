// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import Foundation

public extension AsyncStream {
  @inlinable
  init<S: AsyncSequence>(
    _ sequence: S,
    bufferingPolicy: Continuation.BufferingPolicy = .unbounded
  ) where S.Element == Element {
    self.init(Element.self, bufferingPolicy: bufferingPolicy) { continuation in
      let task = Task {
        do {
          for try await element in sequence {
            if Task.isCancelled {
              break
            }

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

        default:
          break
        }
      }
    }
  }
}

public extension AsyncThrowingStream where Failure == Error {
  @inlinable
  init<S: AsyncSequence>(
    _ sequence: S,
    bufferingPolicy _: Continuation.BufferingPolicy = .unbounded
  ) where S.Element == Element {
    self.init(Element.self, bufferingPolicy: .unbounded) { continuation in
      let task = Task {
        for try await element in sequence {
          if Task.isCancelled {
            break
          }

          continuation.yield(element)
        }

        continuation.finish()
      }

      continuation.onTermination = { termination in
        switch termination {
        case .cancelled: task.cancel()

        default:
          break
        }
      }
    }
  }
}

public extension AsyncSequence {
  @inlinable
  var erasedToAsyncStream: AsyncStream<Element> { .init(self) }

  @inlinable
  var erasedToAsyncThrowingStream: AsyncThrowingStream<Element, Error> { .init(self) }
}

public extension AsyncChannel {
  @inlinable
  static func pipe(
    bufferingPolicy: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded
  ) -> (send: @Sendable (Element) async -> Void, stream: AsyncStream<Element>) {
    let channel = AsyncChannel<Element>()

    return (
      send: { await channel.send($0) }, stream: .init(channel, bufferingPolicy: bufferingPolicy)
    )
  }
}

public extension AsyncThrowingChannel where Failure == Error {
  @inlinable
  static func pipe(
    bufferingPolicy: AsyncThrowingStream<Element, Failure>.Continuation.BufferingPolicy = .unbounded
  ) -> (send: @Sendable (Element) async -> Void, stream: AsyncThrowingStream<Element, Failure>) {
    let channel = AsyncThrowingChannel<Element, Failure>()

    return (
      send: { await channel.send($0) }, stream: .init(channel, bufferingPolicy: bufferingPolicy)
    )
  }
}

public extension FileHandle {
  @inlinable
  var dataBatches: AsyncStream<Data> {
    AsyncStream<Data> { continuation in
      readabilityHandler = { fileHandle in
        let data = fileHandle.availableData

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
