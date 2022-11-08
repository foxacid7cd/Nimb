//
//  AnyAsyncSequence.swift
//  Library
//
//  Created by Yevhenii Matviienko on 08.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

public struct AnyAsyncSequence<Element>: AsyncSequence {
  init<S: AsyncSequence>(sequence: S) where S.Element == Element {
    self._makeAsyncIterator = {
      AnyAsyncIterator(iterator: sequence.makeAsyncIterator())
    }
  }

  public typealias AsyncIterator = AnyAsyncIterator<Element>

  public struct AnyAsyncIterator<Element>: AsyncIteratorProtocol {
    init<I: AsyncIteratorProtocol>(iterator: I) where I.Element == Element {
      var iterator = iterator

      self._next = { try await iterator.next() }
    }

    public typealias Element = Element

    public mutating func next() async throws -> Element? {
      return try await self._next()
    }

    private let _next: () async throws -> Element?
  }

  public func makeAsyncIterator() -> AnyAsyncIterator<Element> {
    return self._makeAsyncIterator()
  }

  let _makeAsyncIterator: () -> AnyAsyncIterator<Element>
}

public extension AsyncSequence {
  func eraseToAnyAsyncSequence() -> AnyAsyncSequence<Element> {
    AnyAsyncSequence(sequence: self)
  }
}
