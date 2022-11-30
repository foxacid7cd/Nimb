//
//  AnyAsyncSequence.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 30.11.2022.
//

public struct AnyAsyncSequence<Element>: AsyncSequence {
  init<S: AsyncSequence>(sequence: S) where S.Element == Element {
    self._makeAsyncIterator = {
      var iterator = sequence.makeAsyncIterator()

      return .init {
        do {
          return try await iterator.next()

        } catch {
          assertionFailure("\(Self.self) must not be used for throwing sequences.")
          return nil
        }
      }
    }
  }

  public typealias AsyncIterator = AnyAsyncIterator<Element>

  public struct AnyAsyncIterator<Element>: AsyncIteratorProtocol {
    init(_next: @escaping () async -> Element?) {
      self._next = _next
    }

    public typealias Element = Element

    public mutating func next() async -> Element? {
      await self._next()
    }

    private let _next: () async -> Element?
  }

  public func makeAsyncIterator() -> AnyAsyncIterator<Element> {
    self._makeAsyncIterator()
  }

  let _makeAsyncIterator: () -> AnyAsyncIterator<Element>
}

public struct AnyAsyncThrowingSequence<Element>: AsyncSequence {
  init<S: AsyncSequence>(sequence: S) where S.Element == Element {
    self._makeAsyncIterator = {
      var iterator = sequence.makeAsyncIterator()

      return .init {
        try await iterator.next()
      }
    }
  }

  public typealias AsyncIterator = AnyAsyncIterator<Element>

  public struct AnyAsyncIterator<Element>: AsyncIteratorProtocol {
    init(_next: @escaping () async throws -> Element?) {
      self._next = _next
    }

    public typealias Element = Element

    public mutating func next() async throws -> Element? {
      try await self._next()
    }

    private let _next: () async throws -> Element?
  }

  public func makeAsyncIterator() -> AnyAsyncIterator<Element> {
    self._makeAsyncIterator()
  }

  let _makeAsyncIterator: () -> AnyAsyncIterator<Element>
}

public extension AsyncSequence {
  func eraseToAnyAsyncSequence() -> AnyAsyncSequence<Element> {
    .init(sequence: self)
  }

  func eraseToAnyAsyncThrowingSequence() -> AnyAsyncThrowingSequence<Element> {
    .init(sequence: self)
  }
}
