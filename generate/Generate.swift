// SPDX-License-Identifier: MIT

import ArgumentParser
import CustomDump
import Foundation
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
    let dataBatches = FileHandle.standardInput.dataBatches
    let generator = Generator(dataBatches)

    let generatedURL = URL(filePath: generatedPath)

    try await generator.writeFiles(to: generatedURL)
  }
}

enum GenerateError: Error { case invalidStandardInputData }
