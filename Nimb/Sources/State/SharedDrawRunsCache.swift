// SPDX-License-Identifier: MIT

import Collections
import ConcurrencyExtras

public final class SharedDrawRunsCache: Sendable {
  private struct Critical {
    var storage: [DrawRunsCachingKey: DrawRun] = [:]
    var orderedKeys: Deque<DrawRunsCachingKey> = []
  }

  private let critical = LockIsolated(Critical())

  public static func shouldCacheDrawRun(forKey key: DrawRunsCachingKey) -> Bool {
    key.text.count < 3
  }

  public func set(drawRun: DrawRun, forKey key: DrawRunsCachingKey) {
    critical.withValue { critical in
      critical.storage[key] = drawRun
      critical.orderedKeys.append(key)
      if critical.storage.count > 80 {
        for _ in 0 ..< 40 {
          let key = critical.orderedKeys.popFirst()!
          critical.storage.removeValue(forKey: key)
        }
      }
    }
  }

  public func drawRun(forKey key: DrawRunsCachingKey) -> DrawRun? {
    critical.withValue { critical in
      critical.storage[key]
    }
  }
}
