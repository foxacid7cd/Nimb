// SPDX-License-Identifier: MIT

import CustomDump

@inlinable public func assertionFailure(_ reason: @autoclosure () -> Any, file: StaticString = #file, line: UInt = #line) {
  Swift.assertionFailure(
    {
      var message = ""
      customDump(reason(), to: &message)

      return message
    }(),
    file: file,
    line: line
  )
}
