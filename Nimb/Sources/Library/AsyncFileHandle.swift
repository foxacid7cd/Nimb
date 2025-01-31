// SPDX-License-Identifier: MIT

import Foundation
import Queue

extension FileHandle {
  var dataBatches: AsyncStream<Data> {
    .init { continuation in
      let asyncQueue = AsyncQueue()

      readabilityHandler = { fileHandle in
        let data = fileHandle.availableData

        asyncQueue.addOperation { @StateActor in
          if data.isEmpty {
            continuation.finish()
          } else {
            continuation.yield(data)
          }
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
