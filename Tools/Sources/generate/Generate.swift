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
    let files = try await Metadata.generateFiles(
      dataBatches: AsyncStream(
        reading: .standardInput
      )
    )
    
    let generatedURL = URL(filePath: generatedPath)
    try? FileManager.default.createDirectory(
      at: generatedURL,
      withIntermediateDirectories: true
    )
    
    for (name, content) in files {
      let fileURL = generatedURL
        .appending(path: "\(name).swift")
      
      try content
        .write(to: fileURL, atomically: true, encoding: .utf8)
      
      print(fileURL.absoluteURL.relativePath)
    }
  }
}

enum GenerateError: Error {
  case invalidStandardInputData
}
