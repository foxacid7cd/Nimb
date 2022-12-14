// Copyright © 2022 foxacid7cd. All rights reserved.

import AppKit

extension NSView {
  func rectsBeingDrawn() -> [CGRect] {
    var rects: UnsafePointer<CGRect>?
    var count = 0
    getRectsBeingDrawn(&rects, count: &count)

    return .init(unsafeUninitializedCapacity: count) { buffer, initializedCount in
      let rectsBuffer = UnsafeBufferPointer(start: rects!, count: count)
      initializedCount = buffer.initialize(fromContentsOf: rectsBuffer)
    }
  }
}

extension NSColor {
  convenience init(rgb: Int, alpha: Double = 1) {
    self.init(
      red: Double((rgb & 0xFF0000) >> 16) / 255.0,
      green: Double((rgb & 0xFF00) >> 8) / 255.0,
      blue: Double(rgb & 0xFF) / 255.0,
      alpha: alpha
    )
  }
}
