// SPDX-License-Identifier: MIT

import Foundation

public struct AsyncMessageBatches<DataBatches: AsyncSequence>: AsyncSequence, Sendable where DataBatches.Element == Data, DataBatches: Sendable {
  init(_ dataBatches: DataBatches) {
    self.dataBatches = dataBatches
  }

  public typealias Element = [Message]

  public struct AsyncIterator: AsyncIteratorProtocol {
    init(_ dataBatchesIterator: DataBatches.AsyncIterator) {
      self.dataBatchesIterator = dataBatchesIterator
    }

    public mutating func next() async throws -> Element? {
      guard let data = try await dataBatchesIterator.next() else {
        return nil
      }

      try Task.checkCancellation()

      return try unpacker.unpack(data)
        .map(Message.init(value:))
    }

    private let unpacker: Unpacker = .init()
    private var dataBatchesIterator: DataBatches.AsyncIterator
  }

  public func makeAsyncIterator() -> AsyncIterator {
    .init(dataBatches.makeAsyncIterator())
  }

  private let dataBatches: DataBatches
}
