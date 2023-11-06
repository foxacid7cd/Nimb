// SPDX-License-Identifier: MIT

import AppKit

public class FloatingPanel: NSPanel {
  public init(contentViewController: NSViewController) {
    super.init(
      contentRect: .init(),
      styleMask: [.titled, .fullSizeContentView],
      backing: .buffered,
      defer: true
    )
    self.contentViewController = contentViewController
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    isMovable = false
    isOpaque = false
    isFloatingPanel = true
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    level = .floating
  }

  override public var canBecomeKey: Bool {
    false
  }

  override public var canBecomeMain: Bool {
    false
  }
}
