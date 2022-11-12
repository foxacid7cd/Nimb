//
//  DrawRun.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 30.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Library

struct DrawRun: Equatable {
  var origin: GridPoint
  var characters: [Character]
  var glyphRun: GlyphRun
  var foregroundColor: CGColor
  var backgroundColor: CGColor

  static func make(origin: GridPoint, characters: [Character], font: NSFont, foregroundColor: CGColor, backgroundColor: CGColor) -> DrawRun {
    let attributedString = NSAttributedString(
      string: String(characters),
      attributes: [.font: font, .ligature: 0]
    )
    let typesetter = CTTypesetterCreateWithAttributedString(attributedString)
    let line = CTTypesetterCreateLine(typesetter, .init(location: 0, length: characters.count))

    var glyphs = [CGGlyph]()
    var positions = [CGPoint]()

    let ctRuns = CTLineGetGlyphRuns(line) as! [CTRun]

    for ctRun in ctRuns {
      let glyphCount = CTRunGetGlyphCount(ctRun)
      let range = CFRange(location: 0, length: glyphCount)

      glyphs += [CGGlyph](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
        CTRunGetGlyphs(ctRun, range, buffer.baseAddress!)
        initializedCount = glyphCount
      }

      positions += [CGPoint](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
        CTRunGetPositions(ctRun, range, buffer.baseAddress!)
        initializedCount = glyphCount
      }
    }

    return .init(
      origin: origin,
      characters: characters,
      glyphRun: .init(
        glyphs: glyphs,
        positions: positions,
        font: font
      ),
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor
    )
  }
}
