//
//  NSView+Nims.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 30.11.2022.
//

import Cocoa

extension NSView {
  var rectsBeingDrawn: [CGRect] {
    var rects: UnsafePointer<CGRect>?
    var count = 0
    self.getRectsBeingDrawn(&rects, count: &count)

    return .init(unsafeUninitializedCapacity: count) { buffer, initializedCount in
      let rectsBuffer = UnsafeBufferPointer(start: rects!, count: count)
      initializedCount = buffer.initialize(fromContentsOf: rectsBuffer)
    }
  }
}
