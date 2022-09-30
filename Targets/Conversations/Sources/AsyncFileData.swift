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
  public typealias Failure = Error
  public typealias AsyncIterator = AsyncThrowingStream<Element, Failure>.AsyncIterator
  
  private let stream: AsyncThrowingStream<Element, Failure>
  
  public init(_ fileHandle: FileHandle) {
    stream = .init { continuation in
      fileHandle.readabilityHandler = { fileHandle in
        let data = fileHandle.availableData
        
        guard !data.isEmpty else {
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
