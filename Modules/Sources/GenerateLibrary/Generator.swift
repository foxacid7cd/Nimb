// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation
import MessagePack
import SwiftSyntax
import SwiftSyntaxBuilder

private let generatableFileTypes: [GeneratableFile.Type] = [
  APIFunctionsFile.self, UIEventsFile.self,
]

public actor Generator {
  public init<S: AsyncSequence>(
    _ dataBatches: S
  ) where S.Element == Data {
    metadataTask = Task<Metadata, Error> {
      var accumulator = [Value]()

      do {
        let unpacker = Unpacker()
        for try await data in dataBatches {
          let values = try await unpacker.unpack(data)

          accumulator += values
        }

        guard let value = accumulator.first, let metadata = Metadata(value) else {
          throw GeneratorError.invalidData(details: "No API metadata.")
        }

        return metadata

      } catch { throw GeneratorError.invalidData(details: "\(error)") }
    }
  }

  public func writeFiles(to directoryURL: URL) async throws {
    try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

    let metadata = try await metadataTask.value

    for type in generatableFileTypes {
      let file = type.init(metadata)

      let fileURL = directoryURL.appending(path: "\(file.name).swift", directoryHint: .notDirectory)

      do {
        try file.sourceFile.formatted().description
          .write(to: fileURL, atomically: true, encoding: .utf8)
      } catch { throw GeneratorError.invalidData(details: "\(error)") }
    }
  }

  private let metadataTask: Task<Metadata, Error>
}

public enum GeneratorError: Error { case invalidData(details: String) }