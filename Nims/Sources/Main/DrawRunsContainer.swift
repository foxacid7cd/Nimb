// SPDX-License-Identifier: MIT

import AppKit
import Collections
import CustomDump
import Library
import SwiftUI

@MainActor
public final class DrawRunsContainer {
  public init(gridLayout: GridLayout, font: NimsFont, appearance: Appearance) {
    rowDrawRuns = makeRowDrawRuns(gridLayout: gridLayout, font: font, appearance: appearance)
  }

  public func render(textUpdate: GridTextUpdate, gridLayout: GridLayout, font: NimsFont, appearance: Appearance) {
    switch textUpdate {
    case .resize:
      rowDrawRuns = makeRowDrawRuns(gridLayout: gridLayout, font: font, appearance: appearance)

    case let .line(origin, _):
      rowDrawRuns[origin.row] = .init(
        origin: .init(x: 0, y: Double(gridLayout.rowsCount - origin.row - 1) * font.cellHeight),
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
        rowDrawRuns[toRow].origin = .init(x: 0, y: Double(gridLayout.rowsCount - toRow - 1) * font.cellHeight)
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
    for row in boundingRect.rows where row > 0 && row < rowDrawRuns.count {
      context.clip(to: [boundingRect * font.cellSize])
      rowDrawRuns[row].draw(at: .init(), to: context, font: font, appearance: appearance)
      context.resetClip()
    }
  }

  private(set) var rowDrawRuns: [RowDrawRun]

  private var cursorDrawRun: CursorDrawRun?
}

@MainActor
private func makeRowDrawRuns(gridLayout: GridLayout, font: NimsFont, appearance: Appearance) -> [RowDrawRun] {
  gridLayout.rowLayouts
    .enumerated()
    .map { row, rowLayout in
      RowDrawRun(
        origin: .init(x: 0, y: Double(gridLayout.rowsCount - row - 1) * font.cellHeight),
        rowLayout: rowLayout,
        font: font,
        appearance: appearance
      )
    }
}

@PublicInit
public struct RowDrawRun {
  @MainActor
  public init(origin: CGPoint, rowLayout: RowLayout, font: NimsFont, appearance: Appearance) {
    var drawRuns = [DrawRun]()

    for rowPart in rowLayout.parts {
      let drawRun = DrawRun(
        origin: .init(
          x: Double(rowPart.range.location) * font.cellSize.width,
          y: 0
        ),
        highlightID: rowPart.highlightID,
        integerSize: .init(columnsCount: rowPart.range.length, rowsCount: 1),
        font: font,
        appearance: appearance,
        text: rowPart.text
      )
      drawRuns.append(drawRun)
    }

    self = .init(
      origin: origin,
      drawRuns: drawRuns
    )
  }

  public var origin: CGPoint
  public var drawRuns: [DrawRun]

  @MainActor
  public func draw(
    at origin: CGPoint,
    to context: CGContext,
    font: NimsFont,
    appearance: Appearance
  ) {
    for drawRun in drawRuns {
      drawRun.draw(at: self.origin + origin, to: context, font: font, appearance: appearance)
    }
  }
}

@PublicInit
public struct DrawRun {
  @MainActor
  public init(origin: CGPoint, highlightID: Highlight.ID, integerSize: IntegerSize, font: NimsFont, appearance: Appearance, text: String) {
    let size = integerSize * font.cellSize

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
        let pointsCount = integerSize.columnsCount * widthDivider + 3

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
      origin: origin,
      highlightID: highlightID,
      integerSize: integerSize,
      glyphRuns: glyphRuns,
      strikethroughPath: strikethroughPath?.cgPath,
      underlinePath: underlinePath?.cgPath,
      underlineLineDashLengths: underlineLineDashLengths
    )
  }

  public var origin: CGPoint
  public var highlightID: Highlight.ID
  public var integerSize: IntegerSize
  public var glyphRuns: [GlyphRun]
  public var strikethroughPath: CGPath?
  public var underlinePath: CGPath?
  public var underlineLineDashLengths: [CGFloat]

  @MainActor
  public func draw(
    at origin: CGPoint,
    to context: CGContext,
    font: NimsFont,
    appearance: Appearance
  ) {
    let origin = self.origin + origin
    let rect = CGRect(
      origin: origin,
      size: integerSize * font.cellSize
    )

    context.setShouldAntialias(false)
    appearance.backgroundColor(for: highlightID).appKit.setFill()
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
  public init?(rowDrawRuns: [RowDrawRun], cursor: Cursor, modeInfo: ModeInfo?, mode: Mode?, font: NimsFont, appearance: Appearance) {
    if let modeInfo, let mode {
      var location = 0
      for drawRun in rowDrawRuns[cursor.position.row].drawRuns {
        let nextLocation = location + drawRun.integerSize.columnsCount
        if cursor.position.column >= location, cursor.position.column < nextLocation {
          let cursorStyle = modeInfo
            .cursorStyles[mode.cursorStyleIndex]

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
                origin: .init(),
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
              position: cursor.position,
              cellFrame: cellFrame,
              highlightID: cursorStyle.attrID ?? 0,
              parentOrigin: .init(column: location, row: cursor.position.row),
              parentDrawRun: drawRun
            )
          }
        }

        location = nextLocation
      }
    }

    return nil
  }

  public var position: IntegerPoint
  public var cellFrame: CGRect
  public var highlightID: Highlight.ID
  public var parentOrigin: IntegerPoint
  public var parentDrawRun: DrawRun

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

    let cursorRectangle = IntegerRectangle(
      origin: position,
      size: .init(columnsCount: 1, rowsCount: 1)
    )
    let cursorRect = (cursorRectangle * font.cellSize)
      .applying(upsideDownTransform)

    context.setShouldAntialias(false)
    cursorBackgroundColor.appKit.setFill()
    cursorRect.fill()

    context.setShouldAntialias(true)
    cursorRect.clip()
    for glyphRun in parentDrawRun.glyphRuns {
      context.textMatrix = glyphRun.textMatrix
      context.textPosition = cursorRect.origin + .init(
        x: -font.cellWidth * Double(position.column - parentOrigin.column),
        y: 0
      )
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
