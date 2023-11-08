// SPDX-License-Identifier: MIT

import AppKit
import Collections
import CustomDump
import Library
import SwiftUI

@PublicInit
public struct GridDrawRuns: Sendable {
  public init(layout: GridLayout, font: NimsFont, appearance: Appearance) {
    rowDrawRuns = []
    renderDrawRuns(for: layout, font: font, appearance: appearance)
  }

  public var rowDrawRuns: [RowDrawRun]
  public var cursorDrawRun: CursorDrawRun?

  public mutating func renderDrawRuns(for layout: GridLayout, font: NimsFont, appearance: Appearance) {
    rowDrawRuns = layout.rowLayouts
      .enumerated()
      .map { row, layout in
        .init(
          row: row,
          layout: layout,
          font: font,
          appearance: appearance,
          old: row < rowDrawRuns.count ? rowDrawRuns[row] : nil
        )
      }
  }

  @MainActor
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
}

@PublicInit
public struct RowDrawRun: Sendable {
  public init(row: Int, layout: RowLayout, font: NimsFont, appearance: Appearance, old: RowDrawRun?) {
    var drawRuns = [DrawRun]()
    var drawRunsCache = [DrawRunsCachingKey: (index: Int, drawRun: DrawRun)]()
    var previousReusedOldDrawRunIndex: Int?
    for part in layout.parts {
      var reusedDrawRun: DrawRun?

      if let old {
        if 
          let index = previousReusedOldDrawRunIndex.map({ $0 + 1 }),
          index < old.drawRuns.endIndex,
          let drawRun = reuseDrawRunIfFits(atIndex: index)
        {
          reusedDrawRun = drawRun
          previousReusedOldDrawRunIndex = index
        } else if let (index, drawRun) = old.drawRunsCache[.init(part)] {
          var drawRun = drawRun
          drawRun.boundingRange = 0 ..< drawRun.text.count
          reusedDrawRun = drawRun
          previousReusedOldDrawRunIndex = index
        } else {
          for index in old.drawRuns.indices {
            if let previousReusedOldDrawRunIndex, index == previousReusedOldDrawRunIndex + 1 {
              continue
            }

            if let drawRun = reuseDrawRunIfFits(atIndex: index) {
              reusedDrawRun = drawRun
              previousReusedOldDrawRunIndex = index
              break
            }
          }
        }

        func reuseDrawRunIfFits(atIndex index: Int) -> DrawRun? {
          let oldDrawRun = old.drawRuns[index]

          guard
            part.highlightID == oldDrawRun.highlightID,
            let range = oldDrawRun.text.range(of: part.text),
            range.lowerBound == oldDrawRun.text.startIndex || range.upperBound == oldDrawRun.text.endIndex
          else {
            return nil
          }

          let lowerBound = oldDrawRun.text.distance(from: oldDrawRun.text.startIndex, to: range.lowerBound)
          let upperBound = oldDrawRun.text.distance(from: oldDrawRun.text.startIndex, to: range.upperBound)

          var drawRun = oldDrawRun
          drawRun.boundingRange = lowerBound ..< upperBound
          return drawRun
        }
      }

      let drawRun = reusedDrawRun ?? .init(
        text: part.text,
        columnsCount: part.range.length,
        highlightID: part.highlightID,
        font: font,
        appearance: appearance
      )
      drawRunsCache[.init(drawRun)] = (
        index: drawRuns.count,
        drawRun: drawRun
      )
      drawRuns.append(drawRun)
    }

    self.drawRuns = drawRuns
    self.drawRunsCache = drawRunsCache
  }

  @PublicInit
  public struct DrawRunsCachingKey: Sendable, Hashable {
    public init(_ drawRun: DrawRun) {
      text = drawRun.text
      highlightID = drawRun.highlightID
    }

    public init(_ rowPart: RowPart) {
      text = rowPart.text
      highlightID = rowPart.highlightID
    }

    public var text: String
    public var highlightID: Highlight.ID
  }

  public var drawRuns: [DrawRun]
  public var drawRunsCache: [DrawRunsCachingKey: (index: Int, drawRun: DrawRun)]

  @MainActor
  public func draw(
    at origin: CGPoint,
    to context: CGContext,
    font: NimsFont,
    appearance: Appearance,
    upsideDownTransform: CGAffineTransform
  ) {
    var currentColumn = 0

    for drawRun in drawRuns {
      let rect = CGRect(
        x: Double(currentColumn) * font.cellWidth + origin.x,
        y: origin.y,
        width: Double(drawRun.boundingRange.count) * font.cellWidth,
        height: font.cellHeight
      )
      .applying(upsideDownTransform)

      drawRun.draw(
        to: context,
        at: rect.origin,
        font: font,
        appearance: appearance
      )

      currentColumn += drawRun.boundingRange.count
    }
  }
}

@PublicInit
public struct DrawRun: Sendable {
  public init(text: String, columnsCount: Int, highlightID: Highlight.ID, font: NimsFont, appearance: Appearance) {
    let size = CGSize(width: Double(columnsCount) * font.cellWidth, height: font.cellHeight)

    let nsFont = font.nsFont(
      isBold: appearance.isBold(for: highlightID),
      isItalic: appearance.isItalic(for: highlightID)
    )
    let attributedString = NSAttributedString(
      string: text,
      attributes: [.font: nsFont]
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
      text: text,
      highlightID: highlightID,
      boundingRange: 0 ..< columnsCount,
      columnsCount: columnsCount,
      glyphRuns: glyphRuns,
      strikethroughPath: strikethroughPath,
      underlinePath: underlinePath,
      underlineLineDashLengths: underlineLineDashLengths
    )
  }

  public var text: String
  public var highlightID: Highlight.ID
  public var boundingRange: Range<Int>
  public var columnsCount: Int
  public var glyphRuns: [GlyphRun]
  public var strikethroughPath: Path?
  public var underlinePath: Path?
  public var underlineLineDashLengths: [CGFloat]

  @MainActor
  public func draw(
    to context: CGContext,
    at origin: CGPoint,
    font: NimsFont,
    appearance: Appearance
  ) {
    context.saveGState()
    defer { context.restoreGState() }

    context.setShouldAntialias(false)

    let rect = CGRect(
      origin: origin,
      size: .init(
        width: Double(boundingRange.count) * font.cellWidth,
        height: font.cellHeight
      )
    )
    rect.clip()

    appearance.backgroundColor(for: highlightID).appKit.setFill()
    context.fill([rect])

    let nsFont = font.nsFont(
      isBold: appearance.isBold(for: highlightID),
      isItalic: appearance.isItalic(for: highlightID)
    )

    context.setShouldAntialias(true)

    context.setLineWidth(1)

    let foregroundColor = appearance.foregroundColor(for: highlightID)

    if let strikethroughPath {
      var offsetAffineTransform = CGAffineTransform(translationX: origin.x, y: origin.y)

      context.addPath(
        strikethroughPath.cgPath.copy(using: &offsetAffineTransform)!
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
        underlinePath.cgPath.copy(using: &offsetAffineTransform)!
      )
      context.setStrokeColor(appearance.specialColor(for: highlightID).appKit.cgColor)
      context.strokePath()
    }

    context.setFillColor(foregroundColor.appKit.cgColor)

    let textPosition = CGPoint(
      x: origin.x - Double(boundingRange.lowerBound) * font.cellWidth,
      y: origin.y
    )
    for glyphRun in glyphRuns {
      context.textMatrix = glyphRun.textMatrix
      context.textPosition = textPosition
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
public struct CursorDrawRun: Sendable {
  public init?(layout: GridLayout, rowDrawRuns: [RowDrawRun], position: IntegerPoint, style: CursorStyle, font: NimsFont, appearance: Appearance) {
    var location = 0
    for drawRun in rowDrawRuns[position.row].drawRuns {
      if
        position.column >= location,
        position.column < location + drawRun.boundingRange.count
      {
        if let cellFrame = style.cellFrame(font: font) {
          self = .init(
            position: position,
            style: style,
            cellFrame: cellFrame,
            highlightID: style.attrID ?? 0,
            parentOrigin: .init(column: location, row: position.row),
            parentDrawRun: drawRun,
            shouldDrawParentText: style.shouldDrawParentText
          )
          return
        }
      }

      location += drawRun.boundingRange.count
    }

    return nil
  }

  public var position: IntegerPoint
  public var style: CursorStyle
  public var cellFrame: CGRect
  public var highlightID: Highlight.ID
  public var parentOrigin: IntegerPoint
  public var parentDrawRun: DrawRun
  public var shouldDrawParentText: Bool

  public var rectangle: IntegerRectangle {
    .init(origin: position, size: .init(columnsCount: 1, rowsCount: 1))
  }

  public mutating func updateParent(with layout: GridLayout, rowDrawRuns: [RowDrawRun]) {
    var location = 0
    for drawRun in rowDrawRuns[position.row].drawRuns {
      if
        position.column >= location,
        position.column < location + drawRun.boundingRange.count
      {
        parentOrigin = .init(column: location, row: position.row)
        parentDrawRun = drawRun
      }

      location += drawRun.boundingRange.count
    }
  }

  @MainActor
  public func draw(to context: CGContext, font: NimsFont, appearance: Appearance, upsideDownTransform: CGAffineTransform) {
    context.saveGState()
    defer { context.restoreGState() }

    let cursorForegroundColor: NimsColor
    let cursorBackgroundColor: NimsColor

    if highlightID == Highlight.DefaultID {
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

    if shouldDrawParentText {
      rect.clip()

      context.setFillColor(cursorForegroundColor.appKit.cgColor)
      context.setShouldAntialias(true)

      let parentRectangle = IntegerRectangle(
        origin: .init(column: parentOrigin.column - parentDrawRun.boundingRange.lowerBound, row: parentOrigin.row),
        size: .init(columnsCount: parentDrawRun.boundingRange.count, rowsCount: 1)
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
    }
  }
}
