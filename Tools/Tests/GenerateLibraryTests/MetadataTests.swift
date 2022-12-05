// Copyright © 2022 foxacid7cd. All rights reserved.

@testable import GenerateLibrary
import MessagePack
import XCTest

class MetadataTests: XCTestCase {
  var filesTask: Task<[(name: String, content: String)]?, Error>!
  
  override func setUp() {
    self.filesTask = Task {
      guard let metadataFixtureURL =  Bundle.module
        .url(forResource: "metadata", withExtension: "msgpack")
      else {
        return nil
      }

      let data = try Data(contentsOf: metadataFixtureURL, options: [])
      
      return try await Metadata.generateFiles(
        dataBatches: AsyncStream([data].async)
      )
    }
  }
  
  func testIsGeneratingOneFile() async throws {
    do {
      guard let files = try await filesTask.value else {
        return XCTFail()
      }
      
      XCTAssertEqual(files.count, 1)
      
    } catch {
      XCTFail("\(error)")
    }
  }
  
  func testIsGeneratingAPIFunctions() async throws {
    do {
      guard let files = try await filesTask.value else {
        return XCTFail()
      }
      
      guard let _ = files.firstIndex(where: { $0.name == "APIFunctions" }) else {
        return XCTFail()
      }
      
    } catch {
      XCTFail("\(error)")
    }
  }
  
  override func tearDown() {
    filesTask = nil
  }
}
