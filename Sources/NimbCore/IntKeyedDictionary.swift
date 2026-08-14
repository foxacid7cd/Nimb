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
      limitedBy limit: Key,
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
      growStorageIfNeeded(for: key)

      keysBackingStore.remove(key)
      if newValue != nil {
        keysBackingStore.updateOrAppend(key)
      }

      valuesBackingStore[key] = newValue
    }

    // Without this, `dictionary[key]?.field = x` goes through get and set,
    // copying the whole Value out and back. The values here are Grids, which
    // own their cell array and draw runs, so that copy is the hottest write in
    // the application. Yielding into the slot mutates it in place.
    _modify {
      if key >= valuesBackingStore.count {
        // Out of range, so there is no slot to yield into. Hand over a
        // temporary and only touch the storage if something was actually
        // assigned — growing here unconditionally would make
        // `dictionary[absentKey]?.field = x`, which is a no-op, allocate.
        var value: Value? = nil
        yield &value
        if value != nil {
          self[key] = value
        }
        return
      }

      let wasPresent = valuesBackingStore[key] != nil
      yield &valuesBackingStore[key]
      let isPresent = valuesBackingStore[key] != nil

      if wasPresent != isPresent {
        if isPresent {
          keysBackingStore.updateOrAppend(key)
        } else {
          keysBackingStore.remove(key)
        }
      }
    }
  }

  private mutating func growStorageIfNeeded(for key: Key) {
    while key >= valuesBackingStore.count {
      valuesBackingStore += .init(
        repeating: nil,
        count: Swift.max(1, valuesBackingStore.count),
      )
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
    rhs: IntKeyedDictionary<Value>,
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
