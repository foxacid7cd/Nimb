// SPDX-License-Identifier: MIT

import AppKit

@main
private enum Nimb {
  static let appDelegate = AppDelegate()

  static func main() {
    NSApplication.shared.delegate = appDelegate
    NSApplication.shared.run()
  }
}
