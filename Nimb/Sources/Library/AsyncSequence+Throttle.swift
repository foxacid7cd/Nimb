// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import ConcurrencyExtras

public extension AsyncSequence where Element: Sendable, Self: Sendable {
  func throttle<C: Clock>(for interval: C.Duration, clock: C, _ combineThrottled: @Sendable @escaping (Element, Element) -> Element) -> AsyncStream<Element> {
    .init { continuation in
      Task {
        let lastEmit = LockIsolated(clock.now)

        let accumulator = LockIsolated<Element?>(nil)
        var scheduled: Task<Void, Never>?

        do {
          for try await element in self {
            try Task.checkCancellation()

            scheduled?.cancel()
            scheduled = nil

            accumulator.withValue { accumulator in
              if accumulator != nil {
                accumulator = combineThrottled(accumulator!, element)
              } else {
                accumulator = element
              }
            }

            let emit = { @Sendable in
              lastEmit.setValue(clock.now)
              accumulator.withValue { accumulator in
                let yieldResult = continuation.yield(accumulator ?? element)
                switch yieldResult {
                case .dropped:
                  Task { @MainActor in
                    logger.error("AsyncSequence+Throttle: dropped element because buffer was full")
                  }

                default:
                  break
                }
                accumulator = nil
              }
            }

            let elapsed = lastEmit.withValue { $0.duration(to: clock.now) }
            if elapsed >= interval {
              emit()
            } else {
              let left = interval - elapsed
              scheduled = Task {
                do {
                  try await Task.sleep(for: left, clock: clock)
                  emit()
                } catch { }
              }
            }
          }
        } catch is CancellationError {
        } catch {
          Task { @MainActor in
            logger.error("AsyncSequence+Throttle: caught unexpected error: \(error)")
          }
        }
        continuation.finish()
      }
    }
    .buffer(policy: .unbounded)
    .eraseToStream()
  }
}
