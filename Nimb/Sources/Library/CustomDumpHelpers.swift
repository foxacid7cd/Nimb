// SPDX-License-Identifier: MIT

import CustomDump

public func cd(_ value: some Any) -> String {
  var string = ""
  customDump(value, to: &string)
  return string
}

public extension DefaultStringInterpolation {
  mutating func appendInterpolation(cd value: some Any) {
    appendInterpolation(
      String(customDumping: value)
    )
  }
}
