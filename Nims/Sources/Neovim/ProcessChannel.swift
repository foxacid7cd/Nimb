// SPDX-License-Identifier: MIT

import Foundation
import MessagePack

public struct ProcessChannel: Channel {
  public init(_ process: Foundation.Process) {
    process.standardOutput = standardOutput
    process.standardInput = standardInput
  }

  public var dataBatches: AsyncStream<Data> {
    standardOutput.fileHandleForReading.dataBatches
  }

  public func write(_ data: Data) throws {
    try standardInput.fileHandleForWriting
      .write(contentsOf: data)
  }

  private let standardOutput = Pipe()
  private let standardInput = Pipe()
}
