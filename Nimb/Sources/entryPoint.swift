// SPDX-License-Identifier: MIT

import AppKit

@main
private enum Nimb {
  static func main() {
    let appDelegate = AppDelegate()
    withExtendedLifetime(appDelegate) {
      NSApplication.shared.setActivationPolicy(.regular)
      NSApplication.shared.delegate = appDelegate
      NSApplication.shared.run()
    }
  }
}
