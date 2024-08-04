// SPDX-License-Identifier: MIT

import Foundation

public extension FileHandle {
  @inlinable
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

      continuation.onTermination = { [weak self] termination in
        guard let self else {
          return
        }

        switch termination {
        case .cancelled:
          readabilityHandler = nil
        default:
          break
        }
      }
    }
  }
}
