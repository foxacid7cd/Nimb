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
    let size = parameters.integerSize * parameters.font.cellSize

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

    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    CTLineGetTypographicBounds(ctLine, &ascent, &descent, nil)
    let bounds = CTLineGetBoundsWithOptions(ctLine, [])

    let xOffset = (bounds.width - size.width) / 2
    let yOffset = (bounds.height - size.height) / 2 - descent

    var spaceGlyph = CGGlyph()
    var space = UniChar((" " as Unicode.Scalar).value)
    CTFontGetGlyphsForCharacters(nsFont, &space, &spaceGlyph, 1)

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

        let advances = [CGSize](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
          CTRunGetAdvances(ctRun, .init(), buffer.baseAddress!)
          initializedCount = glyphCount
        }

        return .init(
          textMatrix: CTRunGetTextMatrix(ctRun),
          glyphs: glyphs,
          positions: positions
            .map { .init(x: $0.x - xOffset, y: $0.y - yOffset) },
          advances: advances
        )
      }

    var strikethroughPath: CGPath?
    if parameters.isStrikethrough {
      let strikethroughY = bounds.height - yOffset - ascent
      let mutablePath = CGMutablePath()
      mutablePath.move(to: .init(x: 0, y: strikethroughY))
      mutablePath.addLine(to: .init(x: size.width, y: strikethroughY))
      strikethroughPath = mutablePath.copy()
    }

    return .init(parameters: parameters, glyphRuns: glyphRuns, strikethroughPath: strikethroughPath)
  }

  private lazy var dispatchQueue = DispatchQueue(
    label: "foxacid7cd.DrawRunsProvider.\(ObjectIdentifier(self))",
    attributes: .concurrent
  )
  private var drawRuns = TreeDictionary<Int, DrawRun>()
  private var deque = Deque<Int>()
}

public struct DrawRunParameters: Hashable {
  var integerSize: IntegerSize
  var text: String
  var font: NimsFont
  var isItalic: Bool
  var isBold: Bool
  var isStrikethrough: Bool

  public var nsFont: NSFont {
    font.nsFont(isBold: isBold, isItalic: isItalic)
  }
}

public struct DrawRun {
  public var parameters: DrawRunParameters
  public var glyphRuns: [GlyphRun]
  public var strikethroughPath: CGPath?

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

    if let strikethroughPath {
      var offsettingTransform = CGAffineTransform(
        translationX: frame.origin.x,
        y: frame.origin.y
      )

      let translatedPath = strikethroughPath
        .copy(using: &offsettingTransform)!

      context.addPath(translatedPath)
      context.setLineWidth(1)
      context.setStrokeColor(foregroundColor.appKit.cgColor)
      context.strokePath()
    }
  }
}

public struct GlyphRun {
  public var textMatrix: CGAffineTransform
  public var glyphs: [CGGlyph]
  public var positions: [CGPoint]
  public var advances: [CGSize]
}
