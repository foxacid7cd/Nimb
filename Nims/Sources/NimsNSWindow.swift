// SPDX-License-Identifier: MIT

import AppKit

class NimsNSWindow: NSWindow {
  var _canBecomeKey = true
  var _canBecomeMain = true

  override var canBecomeKey: Bool {
    _canBecomeKey
  }

  override var canBecomeMain: Bool {
    _canBecomeMain
  }
}
