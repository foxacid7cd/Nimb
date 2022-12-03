// Copyright © 2022 foxacid7cd. All rights reserved.

import Cocoa

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
