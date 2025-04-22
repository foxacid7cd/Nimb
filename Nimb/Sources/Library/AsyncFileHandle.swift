// SPDX-License-Identifier: MIT

import Foundation
import Queue

extension FileHandle {
  var dataBatches: AsyncStream<Data> {
    .init { continuation in
      readabilityHandler = { fileHandle in
        let availableData = fileHandle.availableData

        if availableData.isEmpty {
          continuation.finish()
        } else {
          continuation.yield(availableData)
        }
      }

      continuation.onTermination = { _ in
        self.readabilityHandler = nil
      }
    }
  }
}
