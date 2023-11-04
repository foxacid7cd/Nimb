// SPDX-License-Identifier: MIT

import Foundation

public extension Array {
  func optimalChunkSize(preferredChunkSize: Int) -> Int {
    let chunksCount = (Double(count) / Double(preferredChunkSize)).rounded(.up)
    return Int((Double(count) / chunksCount).rounded(.up))
  }
}
