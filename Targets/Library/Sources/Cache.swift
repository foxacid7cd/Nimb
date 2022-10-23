//
//  Cache.swift
//  Library
//
//  Created by Yevhenii Matviienko on 23.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation

private let dispatchQueue = DispatchQueue(
  label: "\(Bundle.main.bundleIdentifier!).\(#fileID)",
  attributes: .concurrent
)

public class Cache<Key: Hashable, Value> {
  public init() {}

  public subscript(key: Key) -> Value? {
    get {
      dispatchQueue.sync {
        self.dictionary[key]
      }
    }
    set(newValue) {
      dispatchQueue.async(flags: .barrier) {
        self.dictionary[key] = newValue
      }
    }
  }

  private var dictionary = [Key: Value]()
}
