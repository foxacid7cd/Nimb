//
//  GlyphRun.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 23.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit

struct GlyphRun: Equatable {
  var glyphs: [CGGlyph]
  var positions: [CGPoint]
  var font: NSFont

  func positionsWithOffset(dx: Double, dy: Double) -> [CGPoint] {
    self.positions
      .map { .init(x: $0.x + dx, y: $0.y + dy) }
  }
}
