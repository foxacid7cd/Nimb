// SPDX-License-Identifier: MIT

import AppKit

open class CustomView: NSView {
  override open func hitTest(_ point: NSPoint) -> NSView? {
    guard isUserInteractionEnabled else {
      return nil
    }
    return super.hitTest(point)
  }

  public var isUserInteractionEnabled = true
}
