// SPDX-License-Identifier: MIT

import AppKit

class NimsNSWindow: NSWindow {
  var _canBecomeKey = true
  override var canBecomeKey: Bool {
    _canBecomeKey
  }

  var _canBecomeMain = true
  override var canBecomeMain: Bool {
    _canBecomeMain
  }
}
