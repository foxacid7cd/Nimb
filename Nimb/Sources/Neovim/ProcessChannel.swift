// SPDX-License-Identifier: MIT

import Foundation

public struct ProcessChannel: Channel {
  /// Installed once, in `init`. `FileHandle.dataBatches` sets the handle's
  /// `readabilityHandler`, so evaluating it more than once would silently
  /// detach every previously vended stream.
  public let dataBatches: AsyncStream<Data>

  private let standardOutput = Pipe()
  private let standardInput = Pipe()

  public init(_ process: Foundation.Process) {
    process.standardOutput = standardOutput
    process.standardInput = standardInput
    dataBatches = standardOutput.fileHandleForReading.dataBatches
  }

  public func write(_ data: Data) throws {
    try standardInput.fileHandleForWriting
      .write(contentsOf: data)
  }
}
