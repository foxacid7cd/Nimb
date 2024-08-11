// SPDX-License-Identifier: MIT

import CustomDump

public extension DefaultStringInterpolation {
  mutating func appendInterpolation(dump value: some Any) {
    appendInterpolation(
      String(customDumping: value)
    )
  }
}
