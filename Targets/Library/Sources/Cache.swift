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
  public init(capacity: Int, dispatchQueue: DispatchQueue) {
    self.capacity = capacity
    self.dispatchQueue = dispatchQueue
  }

  public func set(value: Value, forKey key: Key) {
    self.dispatchQueue.async(flags: .barrier) {
      if self.keys.count == self.capacity {
        let oldKey = self.keys.removeFirst()
        self.dictionary[oldKey] = nil
      }

      self.keys.append(key)
      self.dictionary[key] = value
    }
  }

  public func value(forKey key: Key) -> Value? {
    self.dispatchQueue.sync {
      self.dictionary[key]
    }
  }

  private let capacity: Int
  private let dispatchQueue: DispatchQueue
  private var dictionary = [Key: Value]()
  private var keys = Deque<Key>()
}
