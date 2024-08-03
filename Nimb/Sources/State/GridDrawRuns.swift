// SPDX-License-Identifier: MIT

import AppKit
import Collections
import CustomDump
import Library
import SwiftUI

@PublicInit
public struct GridDrawRuns: Sendable {
  public init(layout: GridLayout, font: Font, appearance: Appearance) {
    rowDrawRuns = []
    renderDrawRuns(for: layout, font: font, appearance: appearance)
  }

  public var rowDrawRuns: [RowDrawRun]
  public var cursorDrawRun: CursorDrawRun?

  public mutating func renderDrawRuns(
    for layout: GridLayout,
    font: Font,
    appearance: Appearance
  ) {
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
  public func drawBackground(
    to context: CGContext,
    boundingRect: IntegerRectangle,
    font: Font,
    appearance: Appearance,
    upsideDownTransform: CGAffineTransform
  ) {
    let fromRow = max(boundingRect.minRow, 0)
    let toRow = min(boundingRect.maxRow, rowDrawRuns.count)
    guard fromRow < toRow else {
      return
    }
    for row in fromRow ..< toRow {
      rowDrawRuns[row].drawBackground(
        at: .init(x: 0, y: Double(row) * font.cellHeight),
        to: context,
        font: font,
        appearance: appearance,
        upsideDownTransform: upsideDownTransform
      )
    }
  }

  @MainActor
  public func drawForeground(
    to context: CGContext,
    boundingRect: IntegerRectangle,
    font: Font,
    appearance: Appearance,
    upsideDownTransform: CGAffineTransform
  ) {
    let fromRow = max(boundingRect.minRow, 0)
    let toRow = min(boundingRect.maxRow, rowDrawRuns.count)
    guard fromRow < toRow else {
      return
    }
    for row in fromRow ..< toRow {
      rowDrawRuns[row].drawForeground(
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
  public init(
    row: Int,
    layout: RowLayout,
    font: Font,
    appearance: Appearance,
    old: RowDrawRun?
  ) {
    var drawRuns = [DrawRun]()
    var drawRunsCache = [DrawRunsCachingKey: (index: Int, drawRun: DrawRun)]()
    var previousReusedOldDrawRunIndex: Int?
    for part in layout.parts {
      var reusedDrawRun: DrawRun?

      if let old {
        if 
          let index = previousReusedOldDrawRunIndex.map({ $0 + 1 }),
          index < old.drawRuns.endIndex,
          old.drawRuns[index].shouldBeReused(for: part)
        {
          reusedDrawRun = old.drawRuns[index]
          previousReusedOldDrawRunIndex = index
        } else if let (index, drawRun) = old.drawRunsCache[.init(part)] {
          reusedDrawRun = drawRun
          previousReusedOldDrawRunIndex = index
        } else {
          for index in old.drawRuns.indices {
            if
              let previousReusedOldDrawRunIndex,
              index == previousReusedOldDrawRunIndex + 1
            {
              continue
            }
            if old.drawRuns[index].shouldBeReused(for: part) {
              reusedDrawRun = old.drawRuns[index]
              previousReusedOldDrawRunIndex = index
              break
            }
          }
        }
      }

      var drawRun = reusedDrawRun ?? .init(
        text: part.text,
        rowPartCells: part.cells,
        columnsRange: part.columnsRange,
        highlightID: part.highlightID,
        font: font,
        appearance: appearance
      )
      drawRun.columnsRange = part.columnsRange
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
      columnsCount = drawRun.columnsRange.count
    }

    public init(_ rowPart: RowPart) {
      text = rowPart.text
      highlightID = rowPart.highlightID
      columnsCount = rowPart.columnsCount
    }

    public var text: String
    public var highlightID: Highlight.ID
    public var columnsCount: Int
  }

  public var drawRuns: [DrawRun]
  public var drawRunsCache: [DrawRunsCachingKey: (index: Int, drawRun: DrawRun)]

  @MainActor
  public func drawBackground(
    at origin: CGPoint,
    to context: CGContext,
    font: Font,
    appearance: Appearance,
    upsideDownTransform: CGAffineTransform
  ) {
    for drawRun in drawRuns {
      let rect = CGRect(
        x: Double(drawRun.columnsRange.lowerBound) * font.cellWidth + origin.x,
        y: origin.y,
        width: Double(drawRun.columnsRange.count) * font.cellWidth,
        height: font.cellHeight
      )
      .applying(upsideDownTransform)

      drawRun.drawBackground(
        to: context,
        at: rect.origin,
        font: font,
        appearance: appearance
      )
    }
  }

  @MainActor
  public func drawForeground(
    at origin: CGPoint,
    to context: CGContext,
    font: Font,
    appearance: Appearance,
    upsideDownTransform: CGAffineTransform
  ) {
    for drawRun in drawRuns {
      let rect = CGRect(
        x: Double(drawRun.columnsRange.lowerBound) * font.cellWidth + origin.x,
        y: origin.y,
        width: Double(drawRun.columnsRange.count) * font.cellWidth,
        height: font.cellHeight
      )
      .applying(upsideDownTransform)

      drawRun.drawForeground(
        to: context,
        at: rect.origin,
        font: font,
        appearance: appearance
      )
    }
  }
}

@PublicInit
public struct DrawRun: Sendable {
  public init(
    text: String,
    rowPartCells: [RowPart.Cell],
    columnsRange: Range<Int>,
    highlightID: Highlight.ID,
    font: Font,
    appearance: Appearance
  ) {
    let size = CGSize(
      width: Double(columnsRange.count) * font.cellWidth,
      height: font.cellHeight
    )

    let isBold = appearance.isBold(for: highlightID)
    let isItalic = appearance.isItalic(for: highlightID)
    let appKitFont = font.appKit(
      isBold: isBold,
      isItalic: isItalic
    )
    let attributedString = NSAttributedString(
      string: text,
      attributes: [.font: appKitFont]
    )

    let ctTypesetter = CTTypesetterCreateWithAttributedStringAndOptions(
      attributedString,
      nil
    )!
    let ctLine = CTTypesetterCreateLine(ctTypesetter, .init())

    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    var leading: CGFloat = 0
    CTLineGetTypographicBounds(ctLine, &ascent, &descent, &leading)
    let bounds = CTLineGetBoundsWithOptions(ctLine, [])

    let xOffset = (font.cellWidth - bounds.width / Double(columnsRange.count)) /
      2
    let yOffset = (font.cellHeight - bounds.height) / 2 + descent
    let offset = CGPoint(x: xOffset, y: yOffset)

    let ctRuns = CTLineGetGlyphRuns(ctLine) as! [CTRun]

    let glyphRuns = ctRuns
      .map { ctRun -> GlyphRun in
        let glyphCount = CTRunGetGlyphCount(ctRun)

        let glyphs =
          [CGGlyph](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
            CTRunGetGlyphs(ctRun, .init(), buffer.baseAddress!)
            initializedCount = glyphCount
          }

        let positions =
          [CGPoint](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
            CTRunGetPositions(ctRun, .init(), buffer.baseAddress!)
            initializedCount = glyphCount
          }
          .map { $0 + offset }

        let advances =
          [CGSize](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
            CTRunGetAdvances(ctRun, .init(), buffer.baseAddress!)
            initializedCount = glyphCount
          }

        let attributes =
          CTRunGetAttributes(ctRun) as! [NSAttributedString.Key: Any]
        let attributesFont = attributes[.font] as? NSFont

        return .init(
          appKitFont: attributesFont ?? appKitFont,
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
        let pointsCount = columnsRange.count * widthDivider + 3

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
      rowPartCells: rowPartCells,
      highlightID: highlightID,
      columnsRange: columnsRange,
      glyphRuns: glyphRuns,
      strikethroughPath: strikethroughPath,
      underlinePath: underlinePath,
      underlineLineDashLengths: underlineLineDashLengths
    )
  }

  public var text: String
  public var rowPartCells: [RowPart.Cell]
  public var highlightID: Highlight.ID
  public var columnsRange: Range<Int>
  public var glyphRuns: [GlyphRun]
  public var strikethroughPath: Path?
  public var underlinePath: Path?
  public var underlineLineDashLengths: [CGFloat]

  @MainActor
  public func drawBackground(
    to context: CGContext,
    at origin: CGPoint,
    font: Font,
    appearance: Appearance
  ) {
    let rect = CGRect(
      origin: origin,
      size: .init(
        width: Double(columnsRange.count) * font.cellWidth,
        height: font.cellHeight
      )
    )

    context.setFillColor(appearance.backgroundColor(for: highlightID).cg)
    context.fill([rect])
  }

  @MainActor
  public func drawForeground(
    to context: CGContext,
    at origin: CGPoint,
    font: Font,
    appearance: Appearance
  ) {
    context.setLineWidth(1)

    let foregroundColor = appearance.foregroundColor(for: highlightID)

    if let strikethroughPath {
      var offsetAffineTransform = CGAffineTransform(
        translationX: origin.x,
        y: origin.y
      )

      context.addPath(
        strikethroughPath.cgPath.copy(using: &offsetAffineTransform)!
      )
      context.setStrokeColor(foregroundColor.appKit.cgColor)
      context.strokePath()
    }

    if let underlinePath {
      var offsetAffineTransform = CGAffineTransform(
        translationX: origin.x,
        y: origin.y
      )

      if !underlineLineDashLengths.isEmpty {
        context.setLineDash(phase: 0.5, lengths: underlineLineDashLengths)
      }
      context.addPath(
        underlinePath.cgPath.copy(using: &offsetAffineTransform)!
      )
      context
        .setStrokeColor(
          appearance.specialColor(for: highlightID).appKit
            .cgColor
        )
      context.strokePath()
    }

    context.setFillColor(foregroundColor.appKit.cgColor)

    let textPosition = origin
    for glyphRun in glyphRuns {
      context.textMatrix = glyphRun.textMatrix
      context.textPosition = textPosition
      CTFontDrawGlyphs(
        glyphRun.appKitFont,
        glyphRun.glyphs,
        glyphRun.positions,
        glyphRun.glyphs.count,
        context
      )
    }
  }

  public func shouldBeReused(for rowPart: RowPart) -> Bool {
    guard
      text == rowPart.text,
      highlightID == rowPart.highlightID,
      rowPartCells == rowPart.cells,
      columnsRange.count == rowPart.columnsRange.count
    else {
      return false
    }
    return true
  }
}

@PublicInit
public struct GlyphRun: @unchecked Sendable {
  public var appKitFont: NSFont
  public var textMatrix: CGAffineTransform
  public var glyphs: [CGGlyph]
  public var positions: [CGPoint]
  public var advances: [CGSize]
}

@PublicInit
public struct CursorDrawRun: Sendable {
  public init?(
    layout: GridLayout,
    rowDrawRuns: [RowDrawRun],
    origin: IntegerPoint,
    columnsCount: Int,
    style: CursorStyle,
    font: Font,
    appearance: Appearance
  ) {
    var parentOrigin: IntegerPoint?
    var parentDrawRun: DrawRun?
    var cursorColumnsRange: Range<Int>?

    drawRunsLoop:
      for drawRun in rowDrawRuns[origin.row].drawRuns
    {
      if drawRun.columnsRange.contains(origin.column) {
        parentOrigin = .init(
          column: drawRun.columnsRange.lowerBound,
          row: origin.row
        )
        parentDrawRun = drawRun
        for rowPartCell in drawRun.rowPartCells {
          let lowerBound = drawRun.columnsRange.lowerBound + rowPartCell
            .columnsRange.lowerBound
          let upperBound = drawRun.columnsRange.lowerBound + rowPartCell
            .columnsRange.upperBound
          if (lowerBound ..< upperBound).contains(origin.column) {
            cursorColumnsRange = rowPartCell.columnsRange
            break drawRunsLoop
          }
        }
        log.fault("inconsistency error")
        break
      }
    }
    guard
      let parentOrigin,
      let parentDrawRun,
      let cursorColumnsRange,
      let cellFrame = style.cellFrame(
        columnsCount: cursorColumnsRange.count,
        font: font
      )
    else {
      log.fault("inconsistency error")
      return nil
    }
    self = .init(
      origin: origin,
      columnsCount: columnsCount,
      style: style,
      cellFrame: cellFrame,
      highlightID: style.attrID ?? Highlight.defaultID,
      parentOrigin: parentOrigin,
      parentDrawRun: parentDrawRun,
      shouldDrawParentText: style.shouldDrawParentText
    )
  }

  public var origin: IntegerPoint
  public var columnsCount: Int
  public var style: CursorStyle
  public var cellFrame: CGRect
  public var highlightID: Highlight.ID
  public var parentOrigin: IntegerPoint
  public var parentDrawRun: DrawRun
  public var shouldDrawParentText: Bool

  public var rectangle: IntegerRectangle {
    .init(
      origin: origin,
      size: .init(
        columnsCount: columnsCount,
        rowsCount: 1
      )
    )
  }

  public mutating func updateParent(
    with layout: GridLayout,
    rowDrawRuns: [RowDrawRun]
  ) {
    var currentColumn = 0
    for drawRun in rowDrawRuns[origin.row].drawRuns {
      let columnsRange = currentColumn ..< currentColumn + drawRun.columnsRange
        .count
      if columnsRange.contains(origin.column) {
        parentOrigin = .init(column: currentColumn, row: origin.row)
        parentDrawRun = drawRun
      }
      currentColumn += drawRun.columnsRange.count
    }
  }

  @MainActor
  public func draw(
    to context: CGContext,
    font: Font,
    appearance: Appearance,
    upsideDownTransform: CGAffineTransform
  ) {
    let cursorForegroundColor: Color
    let cursorBackgroundColor: Color

    if highlightID == .zero {
      cursorForegroundColor = appearance.defaultBackgroundColor
      cursorBackgroundColor = appearance.defaultForegroundColor

    } else {
      cursorForegroundColor = appearance.foregroundColor(for: highlightID)
      cursorBackgroundColor = appearance.backgroundColor(for: highlightID)
    }

    let offset = origin * font.cellSize
    let rect = cellFrame
      .offsetBy(dx: offset.x, dy: offset.y)
      .applying(upsideDownTransform)

    context.setFillColor(cursorBackgroundColor.cg)
    context.fill([rect])

    if shouldDrawParentText {
      context.saveGState()
      context.clip(to: [rect])

      context.setFillColor(cursorForegroundColor.cg)

      let parentRectangle = IntegerRectangle(
        origin: .init(column: parentOrigin.column, row: parentOrigin.row),
        size: .init(
          columnsCount: parentDrawRun.columnsRange.count,
          rowsCount: 1
        )
      )
      let parentRect = (parentRectangle * font.cellSize)
        .applying(upsideDownTransform)

      for glyphRun in parentDrawRun.glyphRuns {
        context.textMatrix = glyphRun.textMatrix
        context.textPosition = parentRect.origin
        CTFontDrawGlyphs(
          glyphRun.appKitFont,
          glyphRun.glyphs,
          glyphRun.positions,
          glyphRun.glyphs.count,
          context
        )
      }
      context.restoreGState()
    }
  }
}
