// SPDX-License-Identifier: MIT

import AppKit
import Collections
import CustomDump
import Library
import SwiftUI

@MainActor
public final class GridDrawRuns {
  public init(gridLayout: GridLayout, font: NimsFont, appearance: Appearance) {
    let drawRunProvider = DrawRunCachingProvider()
    self.drawRunProvider = drawRunProvider

    rowDrawRuns = makeDrawRuns(gridLayout: gridLayout, font: font, appearance: appearance, drawRunProvider: drawRunProvider)
  }

  public func render(textUpdate: GridTextUpdate, gridLayout: GridLayout, font: NimsFont, appearance: Appearance) {
    switch textUpdate {
    case .resize:
      rowDrawRuns = makeDrawRuns(gridLayout: gridLayout, font: font, appearance: appearance, drawRunProvider: drawRunProvider)

    case let .line(origin, _):
      rowDrawRuns[origin.row] = .init(
        row: origin.row,
        rowLayout: gridLayout.rowLayouts[origin.row],
        font: font,
        appearance: appearance,
        drawRunProvider: drawRunProvider
      )

    case let .scroll(rectangle, offset):
      let copy = rowDrawRuns
      let fromRows = rectangle.minRow ..< rectangle.maxRow
      for fromRow in fromRows {
        let toRow = fromRow - offset.rowsCount
        guard
          toRow >= rectangle.minRow,
          toRow < min(gridLayout.rowsCount, rectangle.maxRow)
        else {
          continue
        }
        rowDrawRuns[toRow] = copy[fromRow]
      }

    case .clear:
      drawRunProvider.clearCache()
      rowDrawRuns = makeDrawRuns(gridLayout: gridLayout, font: font, appearance: appearance, drawRunProvider: drawRunProvider)
    }
  }

  public func draw(
    to context: CGContext,
    boundingRect: IntegerRectangle,
    font: NimsFont,
    appearance: Appearance,
    upsideDownTransform: CGAffineTransform
  ) {
    for row in boundingRect.rows where row >= 0 && row < rowDrawRuns.count {
      rowDrawRuns[row].draw(
        at: .init(x: 0, y: Double(row) * font.cellHeight),
        to: context,
        font: font,
        appearance: appearance,
        upsideDownTransform: upsideDownTransform
      )
    }
  }

  public func clearCache() {
    drawRunProvider.clearCache()
  }

  private(set) var rowDrawRuns: [RowDrawRun]

  private let drawRunProvider: DrawRunCachingProvider
  private var cursorDrawRun: CursorDrawRun?
}

@MainActor
private func makeDrawRuns(
  gridLayout: GridLayout,
  font: NimsFont,
  appearance: Appearance,
  drawRunProvider: DrawRunCachingProvider
) -> [RowDrawRun] {
  gridLayout.rowLayouts
    .enumerated()
    .map {
      .init(
        row: $0,
        rowLayout: $1,
        font: font,
        appearance: appearance,
        drawRunProvider: drawRunProvider
      )
    }
}

@MainActor
private class DrawRunCachingProvider {
  func drawRuns(forRow row: Int, rowParts: [RowPart], font: NimsFont, appearance: Appearance) -> [(drawRun: DrawRun, boundingRange: Range<Int>)] {
    if cachedRows[row] == nil {
      cachedRows[row] = .init(parts: [])
    }

    var newCachedParts = [CachedPart]()

    for rowPart in rowParts {
      if let (drawRun, boundingRange) = cachedRows[row]!.matchingDrawRun(for: rowPart) {
        newCachedParts.append(.init(text: rowPart.text, highlightID: rowPart.highlightID, drawRun: drawRun, boundingRange: boundingRange))
      } else {
        let drawRun = DrawRun(text: rowPart.text, columnsCount: rowPart.range.length, highlightID: rowPart.highlightID, font: font, appearance: appearance)
        newCachedParts.append(.init(text: rowPart.text, highlightID: rowPart.highlightID, drawRun: drawRun, boundingRange: 0 ..< rowPart.text.count))
      }
    }

    cachedRows[row]!.parts = newCachedParts

    return newCachedParts.map { ($0.drawRun, $0.boundingRange) }
  }

  func clearCache() {
    cachedRows = [:]
  }

  private struct CachedRow {
    var parts: [CachedPart]

    func matchingDrawRun(for rowPart: RowPart) -> (drawRun: DrawRun, boundingRange: Range<Int>)? {
      for part in parts {
        guard 
          part.highlightID == rowPart.highlightID,
          let range = part.text.range(of: rowPart.text),
          range.lowerBound == part.text.startIndex || range.upperBound == part.text.endIndex
        else {
          continue
        }

        let lowerBound = part.text.distance(from: part.text.startIndex, to: range.lowerBound)
        let upperBound = part.text.distance(from: part.text.startIndex, to: range.upperBound)
        return (
          drawRun: part.drawRun,
          boundingRange: part.boundingRange.lowerBound + lowerBound ..< part.boundingRange.lowerBound + upperBound
        )
      }

      return nil
    }
  }

  private struct CachedPart {
    var text: String
    var highlightID: Highlight.ID
    var drawRun: DrawRun
    var boundingRange: Range<Int>
  }

  private var cachedRows = IntKeyedDictionary<CachedRow>()
}

@PublicInit
public struct RowDrawRun {
  @MainActor
  fileprivate init(row: Int, rowLayout: RowLayout, font: NimsFont, appearance: Appearance, drawRunProvider: DrawRunCachingProvider) {
    self = .init(
      drawRuns: drawRunProvider.drawRuns(forRow: row, rowParts: rowLayout.parts, font: font, appearance: appearance)
    )
  }

  public var drawRuns: [(drawRun: DrawRun, boundingRange: Range<Int>)]

  @MainActor
  public func draw(
    at origin: CGPoint,
    to context: CGContext,
    font: NimsFont,
    appearance: Appearance,
    upsideDownTransform: CGAffineTransform
  ) {
    var currentColumn = 0
    for (drawRun, boundingRange) in drawRuns {
      let rect = CGRect(
        x: Double(currentColumn) * font.cellWidth + origin.x,
        y: origin.y,
        width: Double(boundingRange.count) * font.cellWidth,
        height: font.cellHeight
      )
      .applying(upsideDownTransform)

      rect.clip()

      drawRun.draw(
        to: context,
        at: rect.origin + .init(x: -Double(boundingRange.lowerBound) * font.cellWidth, y: 0),
        font: font,
        appearance: appearance
      )
      currentColumn += boundingRange.count

      context.resetClip()
    }
  }
}

@PublicInit
public struct DrawRun {
  @MainActor
  public init(text: String, columnsCount: Int, highlightID: Highlight.ID, font: NimsFont, appearance: Appearance) {
    let size = CGSize(width: Double(columnsCount) * font.cellWidth, height: font.cellHeight)

    let nsFont = font.nsFont(
      isBold: appearance.isBold(for: highlightID),
      isItalic: appearance.isItalic(for: highlightID)
    )
    let attributedString = NSAttributedString(
      string: text,
      attributes: [
        .font: nsFont,
        .ligature: 2,
      ]
    )

    let ctTypesetter = CTTypesetterCreateWithAttributedStringAndOptions(attributedString, nil)!
    let ctLine = CTTypesetterCreateLine(ctTypesetter, .init())

    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    var leading: CGFloat = 0
    CTLineGetTypographicBounds(ctLine, &ascent, &descent, &leading)
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

    let decorations = appearance.decorations(for: highlightID)
    if decorations.isStrikethrough {
      let strikethroughY = bounds.height + yOffset - ascent

      var path = Path()
      path.move(to: .init(x: 0, y: strikethroughY))
      path.addLine(to: .init(x: size.width, y: strikethroughY))

      strikethroughPath = path
    }

    var underlinePath: Path?
    var underlineLineDashLengths = [CGFloat]()

    let underlineY: CGFloat = 0
    if decorations.isUnderdashed {
      underlineLineDashLengths = [2, 2]
      drawUnderlinePath { path in
        path.addLines([
          .init(x: 0, y: underlineY),
          .init(x: size.width, y: underlineY),
        ])
      }

    } else if decorations.isUnderdotted {
      underlineLineDashLengths = [1, 1]
      drawUnderlinePath { path in
        path.addLines([
          .init(x: 0, y: underlineY),
          .init(x: size.width, y: underlineY),
        ])
      }

    } else if decorations.isUnderdouble {
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

    } else if decorations.isUndercurl {
      drawUnderlinePath { path in
        let widthDivider = 3

        let xStep = font.cellWidth / Double(widthDivider)
        let pointsCount = columnsCount * widthDivider + 3

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

    } else if decorations.isUnderline {
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

    self = .init(
      columnsCount: columnsCount,
      glyphRuns: glyphRuns,
      strikethroughPath: strikethroughPath?.cgPath,
      underlinePath: underlinePath?.cgPath,
      underlineLineDashLengths: underlineLineDashLengths,
      highlightID: highlightID
    )
  }

  public var columnsCount: Int
  public var glyphRuns: [GlyphRun]
  public var strikethroughPath: CGPath?
  public var underlinePath: CGPath?
  public var underlineLineDashLengths: [CGFloat]
  public var highlightID: Highlight.ID

  @MainActor
  public func draw(
    to context: CGContext,
    at origin: CGPoint,
    font: NimsFont,
    appearance: Appearance
  ) {
    context.setShouldAntialias(false)
    appearance.backgroundColor(for: highlightID).appKit.setFill()
    let rect = CGRect(
      origin: origin,
      size: .init(
        width: Double(columnsCount) * font.cellWidth,
        height: font.cellHeight
      )
    )
    context.fill([rect])

    let nsFont = font.nsFont(
      isBold: appearance.isBold(for: highlightID),
      isItalic: appearance.isItalic(for: highlightID)
    )

    context.setLineWidth(1)

    let foregroundColor = appearance.foregroundColor(for: highlightID)

    if let strikethroughPath {
      var offsetAffineTransform = CGAffineTransform(translationX: origin.x, y: origin.y)

      context.addPath(
        strikethroughPath.copy(using: &offsetAffineTransform)!
      )
      context.setStrokeColor(foregroundColor.appKit.cgColor)
      context.strokePath()
    }

    if let underlinePath {
      var offsetAffineTransform = CGAffineTransform(translationX: origin.x, y: origin.y)

      if !underlineLineDashLengths.isEmpty {
        context.setLineDash(phase: 0.5, lengths: underlineLineDashLengths)
      }
      context.addPath(
        underlinePath.copy(using: &offsetAffineTransform)!
      )
      context.setStrokeColor(appearance.specialColor(for: highlightID).appKit.cgColor)
      context.strokePath()
    }

    context.setShouldAntialias(true)
    for glyphRun in glyphRuns {
      context.textMatrix = glyphRun.textMatrix
      context.textPosition = origin
      context.setFillColor(foregroundColor.appKit.cgColor)

      CTFontDrawGlyphs(
        nsFont,
        glyphRun.glyphs,
        glyphRun.positions,
        glyphRun.glyphs.count,
        context
      )
    }
  }
}

@PublicInit
public struct GlyphRun: Sendable {
  public var textMatrix: CGAffineTransform
  public var glyphs: [CGGlyph]
  public var positions: [CGPoint]
  public var advances: [CGSize]
}

@PublicInit
public struct CursorDrawRun {
  @MainActor
  public init?(gridLayout: GridLayout, rowDrawRuns: [RowDrawRun], cursorPosition: IntegerPoint, cursorStyle: CursorStyle, font: NimsFont, appearance: Appearance) {
    var location = 0
    for (drawRun, boundingRange) in rowDrawRuns[cursorPosition.row].drawRuns {
      if
        cursorPosition.column >= location,
        cursorPosition.column < location + boundingRange.count
      {
        if let cursorShape = cursorStyle.cursorShape {
          let cellFrame: CGRect
          switch cursorShape {
          case .block:
            cellFrame = .init(origin: .init(), size: font.cellSize)

          case .horizontal:
            let size = CGSize(
              width: font.cellWidth,
              height: font.cellHeight / 100.0 * Double(cursorStyle.cellPercentage ?? 25)
            )
            cellFrame = .init(
              origin: .init(x: 0, y: font.cellHeight - size.height),
              size: size
            )

          case .vertical:
            let width = font.cellWidth / 100.0 * Double(cursorStyle.cellPercentage ?? 25)
            cellFrame = CGRect(
              origin: .init(),
              size: .init(width: width, height: font.cellHeight)
            )
          }

          self = .init(
            position: cursorPosition,
            cellFrame: cellFrame,
            highlightID: cursorStyle.attrID ?? 0,
            parentOrigin: .init(column: location, row: cursorPosition.row),
            parentDrawRun: drawRun,
            parentBoundingRange: boundingRange
          )
          return
        }
      }

      location += boundingRange.count
    }

    return nil
  }

  public var position: IntegerPoint
  public var cellFrame: CGRect
  public var highlightID: Highlight.ID
  public var parentOrigin: IntegerPoint
  public var parentDrawRun: DrawRun
  public var parentBoundingRange: Range<Int>

  public var rectangle: IntegerRectangle {
    .init(origin: position, size: .init(columnsCount: 1, rowsCount: 1))
  }

  @MainActor
  public func draw(to context: CGContext, font: NimsFont, appearance: Appearance, upsideDownTransform: CGAffineTransform) {
    let cursorForegroundColor: NimsColor
    let cursorBackgroundColor: NimsColor

    if highlightID == 0 {
      cursorForegroundColor = appearance.backgroundColor(for: parentDrawRun.highlightID)
      cursorBackgroundColor = appearance.foregroundColor(for: parentDrawRun.highlightID)

    } else {
      cursorForegroundColor = appearance.foregroundColor(for: highlightID)
      cursorBackgroundColor = appearance.backgroundColor(for: highlightID)
    }

    let offset = position * font.cellSize
    let rect = cellFrame
      .offsetBy(dx: offset.x, dy: offset.y)
      .applying(upsideDownTransform)

    context.setShouldAntialias(false)
    cursorBackgroundColor.appKit.setFill()
    rect.fill()

    context.setShouldAntialias(true)
    rect.clip()

    context.setFillColor(cursorForegroundColor.appKit.cgColor)

    let parentRectangle = IntegerRectangle(
      origin: .init(column: parentOrigin.column - parentBoundingRange.lowerBound, row: parentOrigin.row),
      size: .init(columnsCount: parentBoundingRange.count, rowsCount: 1)
    )
    let parentRect = (parentRectangle * font.cellSize)
      .applying(upsideDownTransform)

    for glyphRun in parentDrawRun.glyphRuns {
      context.textMatrix = glyphRun.textMatrix
      context.textPosition = parentRect.origin

      CTFontDrawGlyphs(
        font.nsFont(),
        glyphRun.glyphs,
        glyphRun.positions,
        glyphRun.glyphs.count,
        context
      )
    }
    context.resetClip()
  }
}
