//
//  Decorators.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 01.12.2022.
//

import Backbone
import Foundation

public extension RPCService {
  init(destinationFileHandle: FileHandle, sourceFileHandle: FileHandle) {
    self.init(
      packer: Packer(dataDestination: FileHandleDecorator(destinationFileHandle)),
      unpacker: Unpacker(dataSource: FileHandleDecorator(sourceFileHandle))
    )
  }
}

actor FileHandleDecorator: DataSource, DataDestination {
  init(_ fileHandle: FileHandle) {
    self.fileHandle = fileHandle
  }

  func dataBatches() async -> AnyAsyncThrowingSequence<Data> {
    let stream = AsyncStream<Data> { continuation in
      self.fileHandle.readabilityHandler = { fileHandle in
        let data = fileHandle.availableData

        if data.isEmpty {
          continuation.finish()

        } else {
          continuation.yield(data)
        }
      }

      continuation.onTermination = { _ in
        self.fileHandle.readabilityHandler = nil
      }
    }

    return stream.eraseToAnyAsyncThrowingSequence()
  }

  func write(data: Data) async throws {
    try self.fileHandle.write(contentsOf: data)
  }

  private let fileHandle: FileHandle
}
