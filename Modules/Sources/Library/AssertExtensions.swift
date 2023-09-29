// SPDX-License-Identifier: MIT

import CustomDump

@inlinable public func assertionFailure(_ reason: @autoclosure () -> Any, file: StaticString = #file, line: UInt = #line) {
  Swift.assertionFailure(
    .init(customDumping: reason()),
    file: file,
    line: line
  )
}
