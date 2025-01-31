// SPDX-License-Identifier: MIT

import Foundation

extension FileHandle {
  var dataBatches: AsyncStream<Data> {
    .init { continuation in
      readabilityHandler = { fileHandle in
        let data = fileHandle.availableData

        if data.isEmpty {
          continuation.finish()
        } else {
          continuation.yield(data)
        }
      }

      continuation.onTermination = { [weak self] _ in
        guard let self else {
          return
        }

        readabilityHandler = nil
      }
    }
  }
}
