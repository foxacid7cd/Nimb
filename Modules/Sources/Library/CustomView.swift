// SPDX-License-Identifier: MIT

import AppKit

open class CustomView: NSView {
  open var isUserInteractionEnabled = true

  override open func hitTest(_ point: NSPoint) -> NSView? {
    guard isUserInteractionEnabled else {
      return nil
    }
    return super.hitTest(point)
  }
}
