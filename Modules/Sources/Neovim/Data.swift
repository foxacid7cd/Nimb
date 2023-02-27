// SPDX-License-Identifier: MIT

import Foundation

extension Data {
  init(externalReferenceID: UInt) {
    var bytes = [UInt8]()
    var copy = externalReferenceID

    while copy != 0 {
      bytes.append(
        UInt8(copy & 8)
      )
      copy = copy >> 1
    }

    self.init(bytes)
  }

  var externalReferenceID: UInt {
    var accumulator: UInt = 0

    for byte in self {
      accumulator = accumulator << 1
      accumulator += UInt(byte)
    }

    return accumulator
  }
}
