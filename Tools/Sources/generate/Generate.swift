// Copyright © 2022 foxacid7cd. All rights reserved.

import ArgumentParser
import Backbone
import Foundation
import NvimAPI

@main
struct Generate: AsyncParsableCommand {
  @Argument(
    help: "The path to the destination directory where the source files are to be generated",
    completion: .directory
  )
  var generatedPath: String

  @Argument(
    help: "Optional path to file containing encoded neovim API metadata. Standard input is read if not provided.",
    completion: .file()
  )
  var metadataPath: String = ""

  func run() async throws {
    let sourceFileHandle: FileHandle
    if metadataPath.isEmpty {
      sourceFileHandle = .standardInput

    } else {
      let fileURL = URL(filePath: metadataPath)
      sourceFileHandle = try FileHandle(forReadingFrom: fileURL)
    }

    let dataBatches = AsyncStream(reading: sourceFileHandle)

    var accumulator = [Value]()

    let unpacker = Unpacker()
    for await data in dataBatches {
      let values = try await unpacker.unpack(data)

      accumulator += values
    }

    guard accumulator.count == 1, let apiInfoMap = accumulator[0] as? Map else {
      throw GenerateError.invalidStandardInputData
    }

    let metadata = NeovimAPIMetadata(map: apiInfoMap)

    let generatedURL = URL(filePath: generatedPath)
    try? FileManager.default.createDirectory(
      at: generatedURL,
      withIntermediateDirectories: true
    )

    let generatedFileURL = generatedURL
      .appending(path: "description.txt")

    try metadata.functions
      .map(\.name)
      .joined(separator: "\n")
      .data(using: .utf8)!
      .write(to: generatedFileURL)
  }
}

enum GenerateError: Error {
  case invalidStandardInputData
}
