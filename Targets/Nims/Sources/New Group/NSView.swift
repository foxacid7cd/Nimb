//
//  NSView.swift
//  Library
//
//  Created by Yevhenii Matviienko on 18.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit

public extension NSView {
  func rectsBeingDrawn() -> [CGRect] {
    var rects: UnsafePointer<NSRect>!
    var count = 0
    getRectsBeingDrawn(&rects, count: &count)

    return [CGRect](unsafeUninitializedCapacity: count) { buffer, initializedCount in
      buffer.baseAddress!.initialize(from: rects, count: count)
      initializedCount = count
    }
  }
}
