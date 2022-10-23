//
//  Cache.swift
//  Library
//
//  Created by Yevhenii Matviienko on 23.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation

public class Cache<Key: Hashable, Value> {
  public init(dispatchQueue: DispatchQueue) {
    self.dispatchQueue = dispatchQueue
  }

  public subscript(key: Key) -> Value? {
    get {
      self.dispatchQueue.sync {
        self.dictionary[key]
      }
    }
    set(newValue) {
      self.dispatchQueue.async(flags: .barrier) {
        self.dictionary[key] = newValue
      }
    }
  }

  private let dispatchQueue: DispatchQueue
  private var dictionary = [Key: Value]()
}
