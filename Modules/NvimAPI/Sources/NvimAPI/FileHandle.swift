// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation

// actor FileHandleDecorator: DataSource, DataOutputStream {
//  init(_ fileHandle: FileHandle) {
//    self.fileHandle = fileHandle
//  }
//
//  let fileHandle: FileHandle
//
//  func dataBatches() async -> AsyncThrowingStream<Data, Error> {
//    .init { continuation in
//      self.fileHandle.readabilityHandler = { fileHandle in
//        let data = fileHandle.availableData
//
//        if data.isEmpty {
//          continuation.finish()
//
//        } else {
//          continuation.yield(data)
//        }
//      }
//
//      continuation.onTermination = { _ in
//        self.fileHandle.readabilityHandler = nil
//      }
//    }
//  }
//
//  func write(_ data: Data) async throws {
//    try self.fileHandle.write(contentsOf: data)
//  }
// }
