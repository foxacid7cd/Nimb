// Copyright © 2022 foxacid7cd. All rights reserved.

import ArgumentParser
import Foundation
import GenerateLibrary
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

  func run() async throws {
    let dataBatches = AsyncStream(reading: .standardInput)
    let generator = Generator(dataBatches)

    let generatedURL = URL(filePath: generatedPath)

    try await generator.writeFiles(to: generatedURL)
  }
}

enum GenerateError: Error {
  case invalidStandardInputData
}