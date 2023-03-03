// SPDX-License-Identifier: MIT

import Foundation

public struct AsyncMessageBatches<DataBatches: AsyncSequence>: AsyncSequence, Sendable where DataBatches.Element == Data, DataBatches: Sendable {
  init(_ dataBatches: DataBatches) {
    self.dataBatches = dataBatches
  }

  private let dataBatches: DataBatches

  public typealias Element = [Message]

  public func makeAsyncIterator() -> AsyncIterator {
    .init(dataBatches.makeAsyncIterator())
  }

  public struct AsyncIterator: AsyncIteratorProtocol {
    init(_ dataBatchesIterator: DataBatches.AsyncIterator) {
      self.dataBatchesIterator = dataBatchesIterator
    }

    private let unpacker: Unpacker = .init()
    private var dataBatchesIterator: DataBatches.AsyncIterator

    public mutating func next() async throws -> Element? {
      guard let data = try await dataBatchesIterator.next() else {
        return nil
      }

      try Task.checkCancellation()

      return try await unpacker.unpack(data)
        .map(Message.init(value:))
    }
  }
}
