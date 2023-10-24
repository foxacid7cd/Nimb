// SPDX-License-Identifier: MIT

import AppKit
import Collections
import CustomDump
import Library
import SwiftUI

@MainActor
public final class GridDrawRuns {
  public init(gridLayout: GridLayout, font: NimsFont, appearance: Appearance) {
    rowDrawRuns = makeRowDrawRuns(gridLayout: gridLayout, font: font, appearance: appearance)
  }

  public func render(textUpdate: GridTextUpdate, gridLayout: GridLayout, font: NimsFont, appearance: Appearance) {
    switch textUpdate {
    case .resize:
      rowDrawRuns = makeRowDrawRuns(gridLayout: gridLayout, font: font, appearance: appearance)

    case let .line(origin, _):
      rowDrawRuns[origin.row] = .init(
        rowLayout: gridLayout.rowLayouts[origin.row],
        font: font,
        appearance: appearance
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
      rowDrawRuns = makeRowDrawRuns(gridLayout: gridLayout, font: font, appearance: appearance)
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
      let rowRectangle = IntegerRectangle(
        origin: .init(column: boundingRect.origin.column, row: row),
        size: .init(columnsCount: boundingRect.size.columnsCount, rowsCount: 1)
      )

      (rowRectangle * font.cellSize)
        .applying(upsideDownTransform)
        .clip()

      rowDrawRuns[row].draw(at: .init(x: 0, y: Double(rowDrawRuns.count - row - 1) * font.cellHeight), to: context, font: font, appearance: appearance)

      context.resetClip()
    }
  }

  private(set) var rowDrawRuns: [RowDrawRun]

  private var cursorDrawRun: CursorDrawRun?
}

@MainActor
private func makeRowDrawRuns(gridLayout: GridLayout, font: NimsFont, appearance: Appearance) -> [RowDrawRun] {
  gridLayout.rowLayouts
    .map { rowLayout in
      RowDrawRun(
        rowLayout: rowLayout,
        font: font,
        appearance: appearance
      )
    }
}

@PublicInit
public struct RowDrawRun {
  @MainActor
  public init(rowLayout: RowLayout, font: NimsFont, appearance: Appearance) {
    var drawRuns = [DrawRun]()

    for rowPart in rowLayout.parts {
      let drawRun = DrawRun(text: rowPart.text, columnsCount: rowPart.range.length, highlightID: rowPart.highlightID, font: font, appearance: appearance)
      drawRuns.append(drawRun)
    }

    self = .init(
      drawRuns: drawRuns
    )
  }

  public var drawRuns: [DrawRun]

  @MainActor
  public func draw(
    at origin: CGPoint,
    to context: CGContext,
    font: NimsFont,
    appearance: Appearance
  ) {
    var currentColumn = 0
    for drawRun in drawRuns {
      drawRun.draw(to: context, at: .init(x: Double(currentColumn) * font.cellWidth + origin.x, y: origin.y), font: font, appearance: appearance)
      currentColumn += drawRun.columnsCount
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
    for drawRun in rowDrawRuns[cursorPosition.row].drawRuns {
      if
        cursorPosition.column >= location,
        cursorPosition.column < location + drawRun.columnsCount
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
            parentDrawRun: drawRun
          )
          return
        }
      }

      location += drawRun.columnsCount
    }

    return nil
  }

  public var position: IntegerPoint
  public var cellFrame: CGRect
  public var highlightID: Highlight.ID
  public var parentOrigin: IntegerPoint
  public var parentDrawRun: DrawRun

  public var rectangle: IntegerRectangle {
    .init(origin: position, size: .init(columnsCount: 1, rowsCount: 1))
  }

  @MainActor
  public func draw(at origin: CGPoint, to context: CGContext, font: NimsFont, appearance: Appearance, upsideDownTransform: CGAffineTransform) {
    let cursorForegroundColor: NimsColor
    let cursorBackgroundColor: NimsColor

    if highlightID == 0 {
      cursorForegroundColor = appearance.backgroundColor(for: parentDrawRun.highlightID)
      cursorBackgroundColor = appearance.foregroundColor(for: parentDrawRun.highlightID)

    } else {
      cursorForegroundColor = appearance.foregroundColor(for: highlightID)
      cursorBackgroundColor = appearance.backgroundColor(for: highlightID)
    }

    let offset = rectangle.origin * font.cellSize
    let rect = cellFrame
      .offsetBy(dx: offset.x, dy: offset.y)
      .applying(upsideDownTransform)

    context.setShouldAntialias(false)
    cursorBackgroundColor.appKit.setFill()
    rect.fill()

    context.setShouldAntialias(true)
    rect.clip()
    for glyphRun in parentDrawRun.glyphRuns {
      context.textMatrix = glyphRun.textMatrix
      context.textPosition = parentOrigin * font.cellSize
      context.setFillColor(cursorForegroundColor.appKit.cgColor)

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
