//
//  Generate.swift
//
//
//  Created by Yevhenii Matviienko on 01.12.2022.
//

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
    let apiInfoFileURL = URL(fileURLWithPath: apiInfoFilePath, isDirectory: false)
    let fileHandle = try FileHandle(forReadingFrom: apiInfoFileURL)

    // let data = try fileHandle.readToEnd()
    let unpacker = Unpacker(sourceFileHandle: fileHandle)

    await withTaskGroup(of: Void.self) { group in
      group.addTask {
        for await batch in await unpacker.unpackedBatches() {
          print(batch.count)

          guard Task.isCancelled else {
            break
          }
        }
      }

      group.addTask {
        do {
          try await unpacker.run()

        } catch {
          print("run error \(error)")
        }
      }

      await group.waitForAll()
    }

    try await unpacker.run()

    print(123)

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
