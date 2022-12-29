// SPDX-License-Identifier: MIT

import ArgumentParser
import Foundation
import GenerateLibrary
import Library
import MessagePack
import SwiftSyntax
import SwiftSyntaxBuilder

// MARK: - Generate

@main
struct Generate: AsyncParsableCommand {
  @Argument(
    help: "The path to the destination directory where the source files are to be generated",
    completion: .directory
  )
  var generatedPath: String

  func run() async throws {
    let dataBatches = FileHandle.standardInput.dataBatches
    let generator = Generator(dataBatches)

    let generatedURL = URL(filePath: generatedPath)

    try await generator.writeFiles(to: generatedURL)
  }
}

// MARK: - GenerateError

enum GenerateError: Error { case invalidStandardInputData }
