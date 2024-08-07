// SPDX-License-Identifier: MIT

import AppKit

let appDelegate = AppDelegate()
withExtendedLifetime(appDelegate) {
  NSApplication.shared.delegate = appDelegate
  NSApplication.shared.run()
}
