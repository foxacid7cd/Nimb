//
//  Cache.swift
//  Library
//
//  Created by Yevhenii Matviienko on 23.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Collections
import Foundation

public class Cache<Key: Hashable, Value> {
  public init(capacity: Int) {
    self.capacity = capacity
  }

  @MainActor
  public func set(value: Value, forKey key: Key) {
    if self.keys.count == self.capacity {
      let oldKey = self.keys.removeFirst()
      self.dictionary[oldKey] = nil
    }

    self.keys.append(key)
    self.dictionary[key] = value
  }

  @MainActor
  public func value(forKey key: Key) -> Value? {
    self.dictionary[key]
  }

  private let capacity: Int
  @MainActor
  private var dictionary = [Key: Value]()
  @MainActor
  private var keys = Deque<Key>()
}
