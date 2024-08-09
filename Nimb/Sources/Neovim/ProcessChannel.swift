// SPDX-License-Identifier: MIT

import Foundation

public struct ProcessChannel: Channel {
  private let standardOutput = Pipe()
  private let standardInput = Pipe()

  public var dataBatches: AsyncStream<Data> {
    standardOutput.fileHandleForReading.dataBatches
  }

  public init(_ process: Foundation.Process) {
    process.standardOutput = standardOutput
    process.standardInput = standardInput
  }

  public func write(_ data: Data) throws {
    try standardInput.fileHandleForWriting
      .write(contentsOf: data)
  }
}
