// SPDX-License-Identifier: MIT

import Foundation
import MessagePack

struct ProcessChannel: Channel {
  private let standardOutput = Pipe()
  private let standardInput = Pipe()

  init(_ process: Foundation.Process) {
    process.standardOutput = standardOutput
    process.standardInput = standardInput
  }

  var dataBatches: AsyncStream<Data> {
    standardOutput.fileHandleForReading.dataBatches
  }

  func write(_ data: Data) async throws {
    try standardInput.fileHandleForWriting
      .write(contentsOf: data)
  }
}
