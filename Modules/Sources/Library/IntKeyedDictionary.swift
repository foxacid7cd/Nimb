// SPDX-License-Identifier: MIT

import CustomDump

public struct IntKeyedDictionary<Value> {
  public typealias Key = Int
  public typealias Element = (key: Key, value: Value)

  private var keys: Set<Key>
  private var values: [Value?]

  public init(minimumCapacity: Int = 0) {
    keys = .init(minimumCapacity: minimumCapacity)
    values = .init(repeating: nil, count: minimumCapacity)
  }

  public subscript(key: Key) -> Value? {
    get {
      key < values.count ? values[key] : nil
    }

    set(newValue) {
      while key >= values.count {
        values += .init(
          repeating: nil,
          count: max(1, values.count)
        )
      }

      if newValue != nil {
        keys.insert(key)
      } else {
        keys.remove(key)
      }

      values[key] = newValue
    }
  }

  public var count: Int {
    keys.count
  }

  public var isEmpty: Bool {
    keys.isEmpty
  }
}

extension IntKeyedDictionary: ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral elements: (Int, Value)...) {
    self.init(minimumCapacity: elements.count)

    for (key, value) in elements {
      self[key] = value
    }
  }
}

extension IntKeyedDictionary: Sendable where Value: Sendable {}

extension IntKeyedDictionary: Equatable where Value: Equatable {
  public static func == (lhs: IntKeyedDictionary<Value>, rhs: IntKeyedDictionary<Value>) -> Bool {
    lhs.keys == rhs.keys && !lhs.keys.contains(where: { key in
      lhs.values[key] != rhs.values[key]
    })
  }
}

extension IntKeyedDictionary: Hashable where Value: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(count)

    for key in keys {
      hasher.combine(key)

      let value = values[key]!
      hasher.combine(value)
    }
  }
}
