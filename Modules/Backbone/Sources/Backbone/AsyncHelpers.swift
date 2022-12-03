// Copyright © 2022 foxacid7cd. All rights reserved.

import AsyncAlgorithms

public extension AsyncStream {
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
        case .cancelled:
          task.cancel()

        default:
          return
        }
      }
    }
  }
}

public extension AsyncThrowingStream where Failure == Error {
  init<S: AsyncSequence>(_ sequence: S,
                         bufferingPolicy _: Continuation.BufferingPolicy = .unbounded)
    where S.Element == Element
  {
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
        case .cancelled:
          task.cancel()

        default:
          return
        }
      }
    }
  }
}

public extension AsyncChannel {
  static func pipe<Element>(
    bufferingPolicy: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded
  ) -> (send: @Sendable (Element) async -> Void, stream: AsyncStream<Element>) {
    let channel = AsyncChannel<Element>()

    return (
      send: { await channel.send($0) },
      stream: .init(channel, bufferingPolicy: bufferingPolicy)
    )
  }
}

public extension AsyncThrowingChannel where Failure == Error {
  static func pipe<Element>(
    bufferingPolicy: AsyncThrowingStream<Element, Failure>.Continuation.BufferingPolicy = .unbounded
  ) -> (send: @Sendable (Element) async -> Void, stream: AsyncThrowingStream<Element, Failure>) {
    let channel = AsyncThrowingChannel<Element, Failure>()

    return (
      send: { await channel.send($0) },
      stream: .init(channel, bufferingPolicy: bufferingPolicy)
    )
  }
}
