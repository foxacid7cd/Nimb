// SPDX-License-Identifier: MIT

import AppKit
import Collections
import SwiftUI

public class DrawRunCache {
  public init() {}

  @MainActor
  public func drawRun(for text: String, font: NSFont, _ makeDrawRun: () -> DrawRun) -> DrawRun {
    let key = Key(font: font, text: text)

    if let cached = drawRuns[key] {
      return cached
    }

    if deque.count >= 500 {
      drawRuns.removeValue(forKey: deque.popFirst()!)
    }

    let drawRun = makeDrawRun()
    drawRuns[key] = drawRun

    deque.append(key)

    return drawRun
  }

  private struct Key: Hashable {
    var font: NSFont
    var text: String
  }

  private var drawRuns = TreeDictionary<Key, DrawRun>()
  private var deque = Deque<Key>()
}

public struct DrawRun {
  public var text: String
  public var size: CGSize
  public var glyphRuns: [GlyphRun]

  public func draw(at point: CGPoint, with context: CGContext) {
    for glyphRun in glyphRuns {
      context.textMatrix = glyphRun.textMatrix
      CTFontDrawGlyphs(
        glyphRun.font,
        glyphRun.glyphs,
        glyphRun.positions
          .map {
            CGPoint(
              x: $0.x + point.x,
              y: $0.y + point.y - glyphRun.font.descender
            )
          },
        glyphRun.glyphs.count,
        context
      )
    }
  }
}

public struct GlyphRun {
  public var font: NSFont
  public var textMatrix: CGAffineTransform
  public var positions: [CGPoint]
  public var glyphs: [CGGlyph]
}
