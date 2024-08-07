// SPDX-License-Identifier: MIT

import Foundation

public struct AsyncMessageBatches<DataBatches: AsyncSequence>: AsyncSequence,
  Sendable where DataBatches.Element == Data, DataBatches: Sendable
{
  init(_ dataBatches: DataBatches, unpacker: Unpacker) {
    self.dataBatches = dataBatches
    self.unpacker = unpacker
  }

  public typealias Element = [Message]

  public struct AsyncIterator: AsyncIteratorProtocol {
    init(_ dataBatchesIterator: DataBatches.AsyncIterator, unpacker: Unpacker) {
      self.unpacker = unpacker
      self.dataBatchesIterator = dataBatchesIterator
    }

    public mutating func next() async throws -> Element? {
      guard let data = try await dataBatchesIterator.next() else {
        return nil
      }

      try Task.checkCancellation()

      return try await unpacker.unpack(data)
        .map(Message.init(value:))
    }

    private let unpacker: Unpacker
    private var dataBatchesIterator: DataBatches.AsyncIterator
  }

  public func makeAsyncIterator() -> AsyncIterator {
    .init(dataBatches.makeAsyncIterator(), unpacker: unpacker)
  }

  private let dataBatches: DataBatches
  private let unpacker: Unpacker
}
