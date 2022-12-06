// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation
import MessagePack
import SwiftSyntax
import SwiftSyntaxBuilder

private let GeneratableFileTypes: [GeneratableFile.Type] = [
  APIFunctionsFile.self,
  UIEventFile.self,
]

public actor Generator {
  public init<DataBatches: AsyncSequence>(_ dataBatches: DataBatches)
    where DataBatches.Element == Data {
    metadataTask = Task<Metadata, Error> {
      var accumulator = [Value]()

      do {
        let unpacker = Unpacker()
        for try await data in dataBatches {
          let values = try await unpacker.unpack(data)

          accumulator += values
        }

        guard
          let value = accumulator.first,
          let metadata = Metadata(value)
        else {
          throw GeneratorError.invalidDataBatches
        }

        return metadata

      } catch {
        throw GeneratorError.invalidDataBatches
      }
    }
  }

  public func writeFiles(to directoryURL: URL) async throws {
    try? FileManager.default.createDirectory(
      at: directoryURL,
      withIntermediateDirectories: true
    )

    let metadata = try await metadataTask.value

    for type in GeneratableFileTypes {
      let file = type.init(metadata)

      let fileURL = directoryURL
        .appending(
          path: "\(file.name).swift",
          directoryHint: .notDirectory
        )

      do {
        try file.sourceFile
          .formatted()
          .description
          .write(to: fileURL, atomically: true, encoding: .utf8)
      } catch {
        throw GeneratorError.invalidDataBatches
      }
    }
  }

  private let metadataTask: Task<Metadata, Error>
}

public enum GeneratorError: Error {
  case invalidDataBatches
}
