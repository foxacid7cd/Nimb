// Copyright © 2022 foxacid7cd. All rights reserved.

import MessagePack
import XCTest

@testable import GenerateLibrary

private let expectedGeneratedFiles: Set = ["APIFunctions.swift", "UIEvents.swift"]

class GeneratorTests: XCTestCase {
  var temporaryDirectoryURL: URL!
  var generator: Generator!

  override func setUp() {
    temporaryDirectoryURL = FileManager.default.temporaryDirectory.appending(
      path: "\(Self.self)_\(UUID().uuidString)",
      directoryHint: .isDirectory
    )

    let metadataFixtureURL = Bundle.module.url(forResource: "metadata", withExtension: "msgpack")!

    let data = try! Data(contentsOf: metadataFixtureURL, options: [])

    generator = Generator(AsyncStream([data].async))
  }

  func testIsCreatingOnlyExpectedFiles() async throws {
    try await generator.writeFiles(to: temporaryDirectoryURL)

    let files = try FileManager.default.contentsOfDirectory(
      atPath: temporaryDirectoryURL.relativePath
    )

    XCTAssertEqual(Set(files), expectedGeneratedFiles)
  }

  override func tearDown() {
    try? FileManager.default.removeItem(atPath: temporaryDirectoryURL.relativePath)

    generator = nil
  }
}