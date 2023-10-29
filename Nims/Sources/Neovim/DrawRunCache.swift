// SPDX-License-Identifier: MIT

import Collections
import Foundation
import Library

public final class DrawRunCache: @unchecked Sendable {
  @PublicInit
  public struct Key: Sendable, Hashable {
    public var text: String
    public var highlightID: Int
  }

  public static let shared = DrawRunCache()

  public subscript(key: Key) -> DrawRun? {
    get {
      let key = key.hashValue
      return dispatchQueue.sync {
        dictionary[key]
      }
    }
    set {
      let key = key.hashValue
      dispatchQueue.sync(flags: .barrier) {
        keys.append(key)

        if keys.count > maximumCount {
          let expiredKey = keys.removeFirst()
          dictionary.removeValue(forKey: expiredKey)
        }

        dictionary[key] = newValue
      }
    }
  }

  public func clear() {
    dictionary = [:]
    keys = .init()
  }

  private let dispatchQueue = DispatchQueue(
    label: "\(Bundle.main.bundleIdentifier!).DrawRunCache",
    attributes: .concurrent
  )
  private let maximumCount = 100
  private var dictionary = TreeDictionary<Int, DrawRun>()
  private var keys = Deque<Int>()
}
