// Copyright © 2022 foxacid7cd. All rights reserved.

import ArgumentParser
import Foundation
import NvimAPI
import SwiftSyntax
import SwiftSyntaxBuilder

@main
struct Generate: AsyncParsableCommand {
  @Argument(
    help: "The path to the file with binary output of nvim launched with --api-info argument",
    completion: .file()
  )
  var apiInfoFilePath: String

  @Argument(
    help: "The path to the destination directory where the source files are to be generated",
    completion: .directory
  )
  var generatedPath: String

  func run() async throws {
    let apiInfoFileURL = URL(filePath: apiInfoFilePath, directoryHint: .notDirectory)
    let data = try Data(contentsOf: apiInfoFileURL, options: .mappedIfSafe)

    let unpacker = Unpacker()
    let batch = try await unpacker.unpack(data)

    guard batch.count == 1, let apiInfo = batch[0] as? [Map] else {
      throw GenerateError.invalidAPIInfoData
    }

    for element in apiInfo {
      let description = element
        .map {
          let key = $0.key.map { String(reflecting: $0) } ?? "nil"
          let value = $0.value.map { String(reflecting: $0) } ?? "nil"
          return "\(key): \(value)"
        }
        .joined(separator: ", ")

      print(description)
    }

//    let apiInfo = await unpacker.unpackedBatches()
//      .reduce([Value](), +)

    // print(apiInfo)

//    Task {
//      var data = Data()
//      for try await byte in fileHandle.bytes {
//        data.append(byte)
//      }
//
//      print("Data output: \(data.count)")
//    }
//
//    let destination = URL(fileURLWithPath: generatedPath, isDirectory: true)
//
//    try FileManager.default.createDirectory(
//      at: destination,
//      withIntermediateDirectories: true,
//      attributes: nil
//    )
  }
}

enum GenerateError: Error {
  case invalidAPIInfoData
}
