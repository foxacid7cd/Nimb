// Copyright © 2022 foxacid7cd. All rights reserved.

import ArgumentParser
import Foundation
import Library
import MessagePack
import SwiftSyntax
import SwiftSyntaxBuilder

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
    print("Generating...")

    let sourceFileHandle: FileHandle
    if metadataPath.isEmpty {
      sourceFileHandle = .standardInput

    } else {
      let fileURL = URL(filePath: metadataPath)
      sourceFileHandle = try FileHandle(forReadingFrom: fileURL)
    }

    let dataBatches = AsyncStream(reading: sourceFileHandle)

    var accumulator = [MessageValue]()

    let unpacker = Unpacker()
    for await data in dataBatches {
      let values = try await unpacker.unpack(data)

      accumulator += values
    }

    guard accumulator.count == 1, let apiInfoMap = accumulator[0] as? MessageMapValue else {
      throw GenerateError.invalidStandardInputData
    }

    let metadata = Metadata(map: apiInfoMap)

    let generatables: [Generatable] = [
      APIFunctionsFile(metadata: metadata),
    ]

    let generatedURL = URL(filePath: generatedPath)
    try? FileManager.default.createDirectory(
      at: generatedURL,
      withIntermediateDirectories: true
    )

    for generatable in generatables {
      let fileURL = generatedURL
        .appending(path: "\(generatable.name).swift")

      try SourceFile(statements: generatable.generated)
        .formatted()
        .description
        .write(to: fileURL, atomically: true, encoding: .utf8)

      print(fileURL.absoluteURL.relativePath)
    }
  }
}

enum GenerateError: Error {
  case invalidStandardInputData
}
