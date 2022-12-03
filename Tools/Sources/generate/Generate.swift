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

  func run() async throws {
    let dataBatches = AsyncStream(reading: FileHandle.standardInput)

    var accumulator = [Value]()

    let unpacker = Unpacker()
    for await data in dataBatches {
      let values = try await unpacker.unpack(data)

      accumulator += values
    }

    guard accumulator.count == 1, let apiInfo = accumulator[0] as? Map else {
      throw GenerateError.invalidStandardInputData
    }

    let description = apiInfo
      .map { key, value in
        "\(key.map { String(describing: $0) } ?? "nil"): \(value.map { String(describing: $0) } ?? "nil")"
      }
      .joined(separator: "\n")

    let destinationDirectoryURL = URL(
      filePath: generatedPath,
      directoryHint: .isDirectory,
      relativeTo: nil
    )
    try FileManager.default.createDirectory(
      at: destinationDirectoryURL,
      withIntermediateDirectories: true,
      attributes: nil
    )

    let descriptionFileURL = destinationDirectoryURL
      .appending(
        path: "description.txt",
        directoryHint: .notDirectory
      )

    try description.data(using: .utf8)!
      .write(to: descriptionFileURL)

    print(descriptionFileURL)
  }
}

enum GenerateError: Error {
  case invalidStandardInputData
}
