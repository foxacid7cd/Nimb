// SPDX-License-Identifier: MIT

import Foundation
import Queue

extension FileHandle {
  var dataBatches: AsyncStream<Data> {
    .init { continuation in
      readabilityHandler = { fileHandle in
        continuation.yield(fileHandle.availableData)
      }

      continuation.onTermination = { _ in
        self.readabilityHandler = nil
      }
    }
  }
}
