// SPDX-License-Identifier: MIT

import AppKit
import Collections
import Library
import SwiftUI

public class DrawRunsProvider {
  public init() {}

  public func drawRun(with parameters: DrawRunParameters) -> DrawRun {
    let key = parameters.hashValue
    let cached = dispatchQueue.sync {
      drawRuns[key]
    }
    if let cached {
      return cached
    }

    let drawRun = makeDrawRun(with: parameters)

    dispatchQueue.sync(flags: [.barrier]) {
      if deque.count >= 1000 {
        drawRuns.removeValue(
          forKey: deque.popFirst()!
        )
      }
      drawRuns[key] = drawRun
      deque.append(key)
    }

    return drawRun
  }

  private func makeDrawRun(with parameters: DrawRunParameters) -> DrawRun {
    let nsFont = parameters.nsFont
    let attributedString = NSAttributedString(
      string: parameters.text,
      attributes: [
        .foregroundColor: NSColor.green,
        .font: nsFont,
        .ligature: NSNumber(value: 1),
        .strikethroughStyle: NSNumber(value: parameters.isStrikethrough ? 1 : 0),
        .strikethroughColor: NSColor.white,
        .underlineStyle: parameters.underlineStyle,
        .underlineColor: NSColor.brown,
      ]
    )

    let typesetter = CTTypesetterCreateWithAttributedString(attributedString)
    let line = CTTypesetterCreateLine(typesetter, .init())
    let runs = CTLineGetGlyphRuns(line) as! [CTRun]

    var glyphRuns = [GlyphRun]()

    for run in runs {
      let glyphCount = CTRunGetGlyphCount(run)

      let glyphPositions = [CGPoint](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
        CTRunGetPositions(run, .init(), buffer.baseAddress!)
        initializedCount = glyphCount
      }

      let glyphs = [CGGlyph](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
        CTRunGetGlyphs(run, .init(), buffer.baseAddress!)
        initializedCount = glyphCount
      }

//      let attributes = CTRunGetAttributes(run) as NSDictionary
//      for (key, value) in attributes {
//        print("\(key) \(value)")
//      }

      CTRunGetAttributes(run)

      glyphRuns.append(
        .init(
          textMatrix: CTRunGetTextMatrix(run),
          positions: glyphPositions,
          glyphs: glyphs
        )
      )
    }

    return .init(parameters: parameters, glyphRuns: glyphRuns)
  }

  private lazy var dispatchQueue = DispatchQueue(
    label: "foxacid7cd.DrawRunsProvider.\(ObjectIdentifier(self))",
    attributes: .concurrent
  )
  private var drawRuns = TreeDictionary<Int, DrawRun>()
  private var deque = Deque<Int>()
}

public struct DrawRunParameters: Hashable {
  var text: String
  var font: NimsFont
  var isItalic: Bool
  var isBold: Bool
  var isStrikethrough: Bool
  var underlineStyle: NSUnderlineStyle

  public func hash(into hasher: inout Hasher) {
    hasher.combine("text: \(text)")
    hasher.combine("font.id: \(font.id)")
    hasher.combine("isItalic: \(isItalic)")
    hasher.combine("isBold: \(isBold)")
    hasher.combine("isStrikethrough: \(isStrikethrough)")
    hasher.combine("underlineStyle: \(underlineStyle.hashValue)")
  }

  public var nsFont: NSFont {
    font.nsFont(isBold: isBold, isItalic: isItalic)
  }
}

public struct DrawRun {
  public var parameters: DrawRunParameters
  public var glyphRuns: [GlyphRun]

  public func draw(at point: CGPoint, with context: CGContext) {
    let nsFont = parameters.nsFont

    for glyphRun in glyphRuns {
      context.textMatrix = glyphRun.textMatrix
      CTFontDrawGlyphs(
        nsFont,
        glyphRun.glyphs,
        glyphRun.positions
          .map {
            CGPoint(
              x: $0.x + point.x,
              y: $0.y + point.y - nsFont.descender
            )
          },
        glyphRun.glyphs.count,
        context
      )
    }
  }
}

public struct GlyphRun {
  public var textMatrix: CGAffineTransform
  public var positions: [CGPoint]
  public var glyphs: [CGGlyph]
}
