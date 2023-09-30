// SPDX-License-Identifier: MIT

import AppKit
import Collections
import Library
import Neovim
import SwiftUI

@MainActor
public final class DrawRunsProvider {
  public init() {}

  public func drawRun(with parameters: DrawRunParameters) -> DrawRun {
    let key = parameters.hashValue

    if let cached = drawRuns[key] {
      return cached
    }

    let drawRun = makeDrawRun(with: parameters)

    if deque.count >= 500 {
      drawRuns.removeValue(
        forKey: deque.popFirst()!
      )
    }
    drawRuns[key] = drawRun
    deque.append(key)

    return drawRun
  }

  private var drawRuns = TreeDictionary<Int, DrawRun>()
  private var deque = Deque<Int>()

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

    let yOffset = (size.height - bounds.height) / 2 + descent
    let offset = CGPoint(x: 0, y: yOffset)

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
        .map { $0 + offset }

        let advances = [CGSize](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
          CTRunGetAdvances(ctRun, .init(), buffer.baseAddress!)
          initializedCount = glyphCount
        }

        return .init(
          textMatrix: CTRunGetTextMatrix(ctRun),
          glyphs: glyphs,
          positions: positions,
          advances: advances
        )
      }

    var strikethroughPath: Path?

    if parameters.decorations.isStrikethrough {
      let strikethroughY = bounds.height + yOffset - ascent

      var path = Path()
      path.move(to: .init(x: 0, y: strikethroughY))
      path.addLine(to: .init(x: size.width, y: strikethroughY))

      strikethroughPath = path
    }

    var underlinePath: Path?
    var underlineLineDashLengths = [CGFloat]()

    let underlineY: CGFloat = 0.5
    if parameters.decorations.isUnderdashed {
      underlineLineDashLengths = [2, 2]
      drawUnderlinePath { path in
        path.addLines([
          .init(x: 0, y: underlineY),
          .init(x: size.width, y: underlineY),
        ])
      }

    } else if parameters.decorations.isUnderdotted {
      underlineLineDashLengths = [1, 1]
      drawUnderlinePath { path in
        path.addLines([
          .init(x: 0, y: underlineY),
          .init(x: size.width, y: underlineY),
        ])
      }

    } else if parameters.decorations.isUnderdouble {
      drawUnderlinePath { path in
        path.addLines([
          .init(x: 0, y: underlineY),
          .init(x: size.width, y: underlineY),
        ])
        path.addLines([
          .init(x: 0, y: underlineY + 3),
          .init(x: size.width, y: underlineY + 3),
        ])
      }

    } else if parameters.decorations.isUndercurl {
      drawUnderlinePath { path in
        let widthDivider = 3

        let xStep = parameters.font.cellWidth / Double(widthDivider)
        let pointsCount = parameters.integerSize.columnsCount * widthDivider + 3

        let oddUnderlineY = underlineY + 3
        let evenUnderlineY = underlineY

        path.move(to: .init(x: 0, y: oddUnderlineY))
        for index in 1 ..< pointsCount {
          let isEven = index.isMultiple(of: 2)

          path.addLine(
            to: .init(
              x: Double(index) * xStep,
              y: isEven ? evenUnderlineY : oddUnderlineY
            )
          )
        }
      }

    } else if parameters.decorations.isUnderline {
      drawUnderlinePath { path in
        path.move(to: .init(x: 0, y: underlineY))
        path.addLine(to: .init(x: size.width, y: underlineY))
      }
    }

    func drawUnderlinePath(with body: (inout Path) -> Void) {
      var path = Path()
      body(&path)

      underlinePath = path
    }

    return .init(
      parameters: parameters,
      glyphRuns: glyphRuns,
      strikethroughPath: strikethroughPath?.cgPath,
      underlinePath: underlinePath?.cgPath,
      underlineLineDashLengths: underlineLineDashLengths
    )
  }
}

public struct DrawRunParameters: Sendable, Hashable {
  @MainActor
  public var nsFont: NSFont {
    font.nsFont(isBold: isBold, isItalic: isItalic)
  }

  var integerSize: IntegerSize
  var text: String
  var font: NimsFont
  var isItalic: Bool
  var isBold: Bool
  var decorations: Highlight.Decorations
}

public struct DrawRun {
  public var parameters: DrawRunParameters
  public var glyphRuns: [GlyphRun]
  public var strikethroughPath: CGPath?
  public var underlinePath: CGPath?
  public var underlineLineDashLengths: [CGFloat]

  @MainActor
  public func draw(
    at origin: CGPoint,
    to graphicsContext: NSGraphicsContext,
    foregroundColor: Neovim.Color,
    specialColor: Neovim.Color
  ) {
    graphicsContext.saveGraphicsState()
    defer { graphicsContext.restoreGraphicsState() }

    let cgContext = graphicsContext.cgContext
    let nsFont = parameters.font.nsFont()

    CGRect(
      origin: origin,
      size: parameters.integerSize * parameters.font.cellSize
    )
    .clip()

    cgContext.setLineWidth(1)

    if let strikethroughPath {
      var offsetAffineTransform = CGAffineTransform(translationX: origin.x, y: origin.y)

      cgContext.addPath(
        strikethroughPath.copy(using: &offsetAffineTransform)!
      )
      cgContext.setStrokeColor(foregroundColor.appKit.cgColor)
      cgContext.strokePath()
    }

    if let underlinePath {
      cgContext.saveGState()

      var offsetAffineTransform = CGAffineTransform(translationX: origin.x, y: origin.y)

      if !underlineLineDashLengths.isEmpty {
        cgContext.setLineDash(phase: 0.5, lengths: underlineLineDashLengths)
      }
      cgContext.addPath(
        underlinePath.copy(using: &offsetAffineTransform)!
      )
      cgContext.setStrokeColor(specialColor.appKit.cgColor)
      cgContext.strokePath()

      cgContext.restoreGState()
    }

    graphicsContext.shouldAntialias = true
    for glyphRun in glyphRuns {
      cgContext.textMatrix = glyphRun.textMatrix
      cgContext.textPosition = origin
      cgContext.setFillColor(foregroundColor.appKit.cgColor)

      CTFontDrawGlyphs(
        nsFont,
        glyphRun.glyphs,
        glyphRun.positions,
        glyphRun.glyphs.count,
        cgContext
      )
    }
  }
}

public struct GlyphRun: Sendable {
  public var textMatrix: CGAffineTransform
  public var glyphs: [CGGlyph]
  public var positions: [CGPoint]
  public var advances: [CGSize]
}
