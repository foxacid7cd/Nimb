//
//  AsyncFileData.swift
//  Conversations
//
//  Created by Yevhenii Matviienko on 30.09.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation

public struct AsyncFileData: AsyncSequence {
  public typealias Element = Data
  public typealias AsyncIterator = AsyncStream<Data>.AsyncIterator

  private let stream: AsyncStream<Data>

  public init(_ fileHandle: FileHandle) {
    stream = .init { continuation in
      fileHandle.readabilityHandler = { fileHandle in
        let data = fileHandle.availableData

        guard !data.isEmpty else {
          fileHandle.readabilityHandler = nil
          continuation.finish()
          return
        }

        continuation.yield(data)
      }
    }
  }

  public func makeAsyncIterator() -> AsyncIterator {
    stream.makeAsyncIterator()
  }
}
