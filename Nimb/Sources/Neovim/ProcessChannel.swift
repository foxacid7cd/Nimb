// SPDX-License-Identifier: MIT

import Foundation

public struct ProcessChannel: Channel {
  public let outputSidechannel: AsyncStream<Data>

  private let standardOutput = Pipe()
  private let standardInput = Pipe()

  private let outputSidechannelContinuation: AsyncStream<Data>.Continuation

  public var dataBatches: AsyncStream<Data> {
    .init { continuation in
      let task = Task {
        do {
          for await data in standardOutput.fileHandleForReading.dataBatches {
            try Task.checkCancellation()
            continuation.yield(data)
            outputSidechannelContinuation.yield(data)
          }
          continuation.finish()
        } catch { }
      }
      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  public init(_ process: Foundation.Process) {
    process.standardOutput = standardOutput
    process.standardInput = standardInput
    (outputSidechannel, outputSidechannelContinuation) = AsyncStream<Data>.makeStream()
  }

  public func write(_ data: Data) throws {
    try standardInput.fileHandleForWriting
      .write(contentsOf: data)
  }
}
