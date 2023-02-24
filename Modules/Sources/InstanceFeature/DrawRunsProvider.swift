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

    if parameters.decorations.isStrikethrough {
      let strikethroughY = bounds.height - yOffset - ascent
      let mutablePath = CGMutablePath()
      mutablePath.move(to: .init(x: 0, y: strikethroughY))
      mutablePath.addLine(to: .init(x: size.width, y: strikethroughY))

      strikethroughPath = mutablePath.copy(
        strokingWithWidth: 1,
        lineCap: .round,
        lineJoin: .round,
        miterLimit: 0
      )
    }

    var underlinePath: CGPath?

    let underlineY = descent / 2 - 1
    if parameters.decorations.isUnderdashed {
      drawUnderlinePath(dashingPattern: [2, 2]) { path in
        path.move(to: .init(x: xOffset, y: underlineY))
        path.addLine(to: .init(x: size.width + xOffset, y: underlineY))
      }

    } else if parameters.decorations.isUnderdotted {
      drawUnderlinePath(dashingPattern: [1, 2]) { path in
        path.move(to: .init(x: xOffset, y: underlineY))
        path.addLine(to: .init(x: size.width + xOffset, y: underlineY))
      }

    } else if parameters.decorations.isUnderdouble {
      drawUnderlinePath { path in
        path.move(to: .init(x: xOffset, y: underlineY))
        path.addLine(to: .init(x: size.width + xOffset, y: underlineY))

        path.move(to: .init(x: xOffset, y: underlineY + 2))
        path.addLine(to: .init(x: size.width + xOffset, y: underlineY + 2))
      }

    } else if parameters.decorations.isUndercurl {
      drawUnderlinePath { path in
        let widthDivider = 3

        let xStep = parameters.font.cellWidth / Double(widthDivider)
        let pointsCount = parameters.integerSize.columnsCount * widthDivider + 2

        let oddUnderlineY = underlineY + 1
        let evenUnderlineY = underlineY - 1
        path.move(to: .init(x: xOffset, y: oddUnderlineY))
        for index in 1 ..< pointsCount - 1 {
          let isEven = index.isMultiple(of: 2)
          path.addLine(
            to: .init(
              x: Double(index) * xStep + xOffset,
              y: isEven ? evenUnderlineY : oddUnderlineY
            )
          )
        }
      }

    } else if parameters.decorations.isUnderline {
      drawUnderlinePath { path in
        path.move(to: .init(x: xOffset, y: underlineY))
        path.addLine(to: .init(x: size.width + xOffset, y: underlineY))
      }
    }

    func drawUnderlinePath(dashingPattern: [CGFloat] = [], with mutatePath: (CGMutablePath) -> Void) {
      let mutablePath = CGMutablePath()
      mutatePath(mutablePath)

      underlinePath = mutablePath.copy()
    }

    return .init(
      parameters: parameters,
      glyphRuns: glyphRuns,
      strikethroughPath: strikethroughPath,
      underlinePath: underlinePath
    )
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
  var decorations: Highlight.Decorations

  public var nsFont: NSFont {
    font.nsFont(isBold: isBold, isItalic: isItalic)
  }
}

public struct DrawRun {
  public var parameters: DrawRunParameters
  public var glyphRuns: [GlyphRun]
  public var strikethroughPath: CGPath?
  public var underlinePath: CGPath?

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

    context.setShouldAntialias(false)

    var offsettingTransform = CGAffineTransform(
      translationX: frame.origin.x,
      y: frame.origin.y
    )

    if let strikethroughPath {
      let translatedPath = strikethroughPath
        .copy(using: &offsettingTransform)!

      context.addPath(translatedPath)
      context.setStrokeColor(specialColor.appKit.cgColor)
      context.strokePath()
    }

    if let underlinePath {
      let translatedPath = underlinePath
        .copy(using: &offsettingTransform)!

      context.addPath(translatedPath)
      context.setStrokeColor(specialColor.appKit.cgColor)
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
