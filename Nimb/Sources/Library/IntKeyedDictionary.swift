// SPDX-License-Identifier: MIT

import Collections

public struct IntKeyedDictionary<Value> {
  public typealias Key = Int
  public typealias Element = (key: Key, value: Value)

  public struct Values: RandomAccessCollection, Sequence {
    public typealias Element = Value

    private let dictionary: IntKeyedDictionary

    public var count: Int {
      keysBackingStore.count
    }

    public var isEmpty: Bool {
      keysBackingStore.isEmpty
    }

    public var underestimatedCount: Int {
      keysBackingStore.underestimatedCount
    }

    public var startIndex: Key {
      keysBackingStore.startIndex
    }

    public var endIndex: Key {
      keysBackingStore.endIndex
    }

    private var keysBackingStore: OrderedSet<Key> {
      dictionary.keysBackingStore
    }

    private var valuesBackingStore: [Value?] {
      dictionary.valuesBackingStore
    }

    init(_ dictionary: IntKeyedDictionary<Value>) {
      self.dictionary = dictionary
    }

    public subscript(position: Int) -> Value {
      let key = keysBackingStore[position]
      return valuesBackingStore[key]!
    }

    public subscript(bounds: Range<Key>) -> ArraySlice<Value> {
      let array = keysBackingStore[bounds]
        .map { valuesBackingStore[$0]! }

      return .init(array)
    }

    public func makeIterator() -> AnyIterator<Value> {
      var keysIterator = keysBackingStore.makeIterator()

      return AnyIterator {
        if let key = keysIterator.next() {
          valuesBackingStore[key]!

        } else {
          nil
        }
      }
    }

    public func distance(from start: Key, to end: Key) -> Int {
      keysBackingStore.distance(from: start, to: end)
    }

    public func formIndex(before i: inout Key) {
      keysBackingStore.formIndex(before: &i)
    }

    public func formIndex(after i: inout Key) {
      keysBackingStore.formIndex(after: &i)
    }

    public func index(_ i: Key, offsetBy distance: Int) -> Key {
      keysBackingStore.index(i, offsetBy: distance)
    }

    public func index(
      _ i: Key,
      offsetBy distance: Int,
      limitedBy limit: Key
    )
      -> Key?
    {
      keysBackingStore.index(i, offsetBy: distance, limitedBy: limit)
    }

    public func index(after i: Key) -> Key {
      keysBackingStore.index(after: i)
    }

    public func index(before i: Key) -> Key {
      keysBackingStore.index(before: i)
    }
  }

  private var keysBackingStore: OrderedSet<Key>
  private var valuesBackingStore: [Value?]

  public var count: Int {
    keysBackingStore.count
  }

  public var isEmpty: Bool {
    keysBackingStore.isEmpty
  }

  public var keys: OrderedSet<Key> {
    keysBackingStore
  }

  public var values: Values {
    .init(self)
  }

  public init(minimumCapacity: Int = 0) {
    keysBackingStore = .init(minimumCapacity: minimumCapacity)
    valuesBackingStore = .init(repeating: nil, count: minimumCapacity)
  }

  public subscript(key: Key) -> Value? {
    get {
      key < valuesBackingStore.count ? valuesBackingStore[key] : nil
    }

    set(newValue) {
      while key >= valuesBackingStore.count {
        valuesBackingStore += .init(
          repeating: nil,
          count: Swift.max(1, valuesBackingStore.count)
        )
      }

      keysBackingStore.remove(key)
      if newValue != nil {
        keysBackingStore.updateOrAppend(key)
      }

      valuesBackingStore[key] = newValue
    }
  }

  @inlinable
  @discardableResult
  public mutating func removeValue(forKey key: Key) -> Value? {
    let value = self[key]
    self[key] = nil
    return value
  }
}

extension IntKeyedDictionary: ExpressibleByDictionaryLiteral {
  @inlinable
  public init(dictionaryLiteral elements: (Int, Value)...) {
    self.init(minimumCapacity: elements.count)

    for (key, value) in elements {
      self[key] = value
    }
  }
}

extension IntKeyedDictionary: Sendable where Value: Sendable { }

extension IntKeyedDictionary: Equatable where Value: Equatable {
  public static func == (
    lhs: IntKeyedDictionary<Value>,
    rhs: IntKeyedDictionary<Value>
  )
    -> Bool
  {
    lhs.keysBackingStore == rhs.keysBackingStore && !lhs.keysBackingStore
      .contains(where: { key in
        lhs.valuesBackingStore[key] != rhs.valuesBackingStore[key]
      })
  }
}

extension IntKeyedDictionary: Hashable where Value: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(count)

    for key in keysBackingStore {
      hasher.combine(key)
      hasher.combine(valuesBackingStore[key]!)
    }
  }
}

extension IntKeyedDictionary: Sequence {
  public func makeIterator() -> Iterator {
    .init(self)
  }

  public struct Iterator: IteratorProtocol {
    private let dictionary: IntKeyedDictionary<Value>
    private var currentKeyIndex: OrderedSet<Int>.Index

    fileprivate init(_ dictionary: IntKeyedDictionary<Value>) {
      self.dictionary = dictionary
      currentKeyIndex = dictionary.keysBackingStore.startIndex
    }

    public mutating func next() -> (key: Int, value: Value)? {
      guard currentKeyIndex != dictionary.keysBackingStore.endIndex else {
        return nil
      }

      let key = dictionary.keysBackingStore[currentKeyIndex]
      currentKeyIndex = dictionary.keysBackingStore
        .index(after: currentKeyIndex)

      let value = dictionary.valuesBackingStore[key]!
      return (key, value)
    }
  }
}
