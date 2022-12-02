//
//  DrawRun.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import Cocoa

struct DrawRun: Equatable {
  var origin: Point
  var glyphRuns: [GlyphRun]
  var cgFrame: CGRect

  static func make(origin: Point, cgFrame: CGRect, attributedString: NSAttributedString) -> DrawRun {
    let typesetter = CTTypesetterCreateWithAttributedString(attributedString)
    let line = CTTypesetterCreateLine(typesetter, .init(location: 0, length: 0))

    let ctRuns = CTLineGetGlyphRuns(line) as! [CTRun]

    let glyphRuns = ctRuns
      .map { ctRun in
        let glyphCount = CTRunGetGlyphCount(ctRun)
        let range = CFRange(location: 0, length: glyphCount)

        let attributes = CTRunGetAttributes(ctRun) as NSDictionary
        let font = attributes.value(forKey: NSAttributedString.Key.font.rawValue) as! NSFont
        let foregroundColor = attributes.value(forKey: NSAttributedString.Key.foregroundColor.rawValue) as! NSColor
        let backgroundColor = attributes.value(forKey: NSAttributedString.Key.backgroundColor.rawValue) as! NSColor

        let glyphs = [CGGlyph](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
          CTRunGetGlyphs(ctRun, range, buffer.baseAddress!)
          initializedCount = glyphCount
        }

        let positions = [CGPoint](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
          CTRunGetPositions(ctRun, range, buffer.baseAddress!)
          initializedCount = glyphCount
        }

        let stringRange = CTRunGetStringRange(ctRun)

        return GlyphRun(
          glyphs: glyphs,
          positions: positions,
          stringRange: NSRange(
            location: stringRange.location,
            length: stringRange.length
          ),
          font: font,
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor
        )
      }

    return .init(
      origin: origin,
      glyphRuns: glyphRuns,
      cgFrame: cgFrame
    )
  }
}

struct GlyphRun: Equatable {
  var glyphs: [CGGlyph]
  var positions: [CGPoint]
  var stringRange: NSRange
  var font: NSFont
  var foregroundColor: NSColor
  var backgroundColor: NSColor

  func positionsWithOffset(dx: Double, dy: Double) -> [CGPoint] {
    positions
      .map { .init(x: $0.x + dx, y: $0.y + dy) }
  }
}
