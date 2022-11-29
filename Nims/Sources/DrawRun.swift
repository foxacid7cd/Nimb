//
//  DrawRun.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import Cocoa

struct DrawRun: Equatable {
  var origin: GridPoint
  var characters: [Character]
  var glyphRun: GlyphRun
  
  static func make(origin: GridPoint, characters: [Character], font: NSFont) -> DrawRun {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = CTFontGetLeading(font)
    paragraphStyle.allowsDefaultTighteningForTruncation = false
    paragraphStyle.paragraphSpacing = 0
    
    let attributedString = NSAttributedString(
      string: String(characters),
      attributes: [.font: font, .paragraphStyle: paragraphStyle.copy()]
    )
    let typesetter = CTTypesetterCreateWithAttributedString(attributedString)
    let line = CTTypesetterCreateLine(typesetter, .init(location: 0, length: 0))
    
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
      )
    )
  }
}

struct GlyphRun: Equatable {
  var glyphs: [CGGlyph]
  var positions: [CGPoint]
  var font: NSFont

  func positionsWithOffset(dx: Double, dy: Double) -> [CGPoint] {
    self.positions
      .map { .init(x: $0.x + dx, y: $0.y + dy) }
  }
}
