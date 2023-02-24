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
        .font: nsFont,
        .ligature: 2,
      ]
    )
    let ctTypesetter = CTTypesetterCreateWithAttributedStringAndOptions(attributedString, nil)!
    let ctLine = CTTypesetterCreateLine(ctTypesetter, .init())

    var descent: CGFloat = 0
    CTLineGetTypographicBounds(ctLine, nil, &descent, nil)
    let bounds = CTLineGetBoundsWithOptions(ctLine, [])
    let yOffset = bounds.height - parameters.font.cellHeight - descent

    let ctRuns = CTLineGetGlyphRuns(ctLine) as! [CTRun]

    let glyphRuns = ctRuns
      .map { ctRun -> GlyphRun in
        let glyphCount = CTRunGetGlyphCount(ctRun)

        let glyphs = [CGGlyph](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
          CTRunGetGlyphs(ctRun, .init(), buffer.baseAddress!)
          initializedCount = glyphCount
        }

        let positions = [CGPoint](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
          CTRunGetPositions(ctRun, .init(), buffer.baseAddress!)
          initializedCount = glyphCount
        }

        return .init(
          textMatrix: CTRunGetTextMatrix(ctRun),
          glyphs: glyphs,
          positions: positions
            .map { .init(x: $0.x, y: $0.y - yOffset) }
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

  public func hash(into hasher: inout Hasher) {
    hasher.combine("text: \(text)")
    hasher.combine("font.id: \(font.id)")
    hasher.combine("isItalic: \(isItalic)")
    hasher.combine("isBold: \(isBold)")
    hasher.combine("isStrikethrough: \(isStrikethrough)")
  }

  public var nsFont: NSFont {
    font.nsFont(isBold: isBold, isItalic: isItalic)
  }
}

public struct DrawRun {
  public var parameters: DrawRunParameters
  public var glyphRuns: [GlyphRun]

  public func draw(
    at frame: CGRect,
    to context: CGContext,
    foregroundColor: NimsColor,
    backgroundColor: NimsColor,
    specialColor: NimsColor
  ) {
    context.setShouldAntialias(false)
    context.setFillColor(backgroundColor.appKit.cgColor)
    context.fill([frame])

    context.setShouldAntialias(true)
    context.setFillColor(foregroundColor.appKit.cgColor)
    let nsFont = parameters.font.nsFont()
    for glyphRun in glyphRuns {
      CTFontDrawGlyphs(
        nsFont,
        glyphRun.glyphs,
        glyphRun.positions
          .map { .init(x: $0.x + frame.origin.x, y: $0.y + frame.origin.y) },
        glyphRun.glyphs.count,
        context
      )
    }
  }
}

public struct GlyphRun {
  public var textMatrix: CGAffineTransform
  public var glyphs: [CGGlyph]
  public var positions: [CGPoint]
}
