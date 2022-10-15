//
//  AnyAsyncSequence.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AsyncAlgorithms

public struct AnyAsyncSequence<Element>: AsyncSequence {
  public init(channel: AsyncChannel<Element>) {
    self.channel = channel
  }

  public typealias AsyncIterator = AsyncChannel<Element>.Iterator

  public func makeAsyncIterator() -> AsyncIterator {
    self.channel.makeAsyncIterator()
  }

  private let channel: AsyncChannel<Element>
}
