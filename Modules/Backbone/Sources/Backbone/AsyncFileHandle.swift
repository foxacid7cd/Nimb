// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation

public extension AsyncStream<Data> {
  init(reading fileHandle: FileHandle) {
    self.init { continuation in
      fileHandle.readabilityHandler = { fileHandle in
        let data = fileHandle.availableData

        if data.isEmpty {
          fileHandle.readabilityHandler = nil

          continuation.finish()

        } else {
          continuation.yield(data)
        }
      }

      continuation.onTermination = { termination in
        switch termination {
        case .cancelled:
          fileHandle.readabilityHandler = nil

        default:
          break
        }
      }
    }
  }
}
