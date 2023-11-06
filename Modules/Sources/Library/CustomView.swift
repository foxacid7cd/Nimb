// SPDX-License-Identifier: MIT

import AppKit

public class CustomView: NSView {
  public var isUserInteractionEnabled = true

  override public func hitTest(_ point: NSPoint) -> NSView? {
    guard isUserInteractionEnabled else {
      return nil
    }
    return super.hitTest(point)
  }
}
