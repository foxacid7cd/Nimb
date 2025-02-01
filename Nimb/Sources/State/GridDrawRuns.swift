// SPDX-License-Identifier: MIT

import AppKit
import Collections
import ConcurrencyExtras
import CustomDump
import SwiftUI

@PublicInit
public struct GridDrawRuns: Sendable {
  public var rowDrawRuns: [RowDrawRun]
  public var cursorDrawRun: CursorDrawRun?

  public init(
    layout: GridLayout,
    font: Font,
    appearance: Appearance
  ) {
    rowDrawRuns = []
    renderDrawRuns(for: layout, font: font, appearance: appearance)
  }

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
        columnsRange: boundingRect.columns,
        at: .init(x: 0, y: Double(row) * font.cellHeight),
        to: context,
        font: font,
        appearance: appearance,
        upsideDownTransform: upsideDownTransform
      )
    }
  }

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
        columnsRange: boundingRect.columns,
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
  public var drawRuns: [DrawRun]
  public var drawRunsCache: [RowPartContent: (index: Int, drawRun: DrawRun)]

  public init(
    row: Int,
    layout: RowLayout,
    font: Font,
    appearance: Appearance,
    old: RowDrawRun?
  ) {
    var drawRuns = [DrawRun]()
    var drawRunsCache = [RowPartContent: (index: Int, drawRun: DrawRun)]()
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
        } else if let (index, drawRun) = old.drawRunsCache[part.content] {
          reusedDrawRun = drawRun
          previousReusedOldDrawRunIndex = index
        }
      }

      var drawRun = reusedDrawRun ?? DrawRun(
        rowPartContent: part.content,
        originColumn: part.originColumn,
        highlightID: part.highlightID,
        font: font,
        appearance: appearance
      )
      drawRun.originColumn = part.originColumn
      drawRun.highlightID = part.highlightID
      drawRunsCache[part.content] = (
        index: drawRuns.count,
        drawRun: drawRun
      )
      drawRuns.append(drawRun)
    }

    self.drawRuns = drawRuns
    self.drawRunsCache = drawRunsCache
  }

  public func drawBackground(
    columnsRange: Range<Int>,
    at origin: CGPoint,
    to context: CGContext,
    font: Font,
    appearance: Appearance,
    upsideDownTransform: CGAffineTransform
  ) {
    for drawRun in drawRuns where drawRun.columnsRange.overlaps(columnsRange) {
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

  public func drawForeground(
    columnsRange: Range<Int>,
    at origin: CGPoint,
    to context: CGContext,
    font: Font,
    appearance: Appearance,
    upsideDownTransform: CGAffineTransform
  ) {
    for drawRun in drawRuns where drawRun.columnsRange.overlaps(columnsRange) {
      let rect = CGRect(
        x: Double(drawRun.columnsRange.lowerBound) * font.cellWidth + origin.x,
        y: origin.y,
        width: Double(drawRun.columnsRange.count) * font.cellWidth,
        height: font.cellHeight
      )
      .applying(upsideDownTransform)

      drawRun.drawForeground(
        to: context,
        at: rect,
        font: font,
        appearance: appearance
      )
    }
  }
}

@PublicInit
public struct DrawRun: Sendable {
  public var rowPartContent: RowPartContent
  public var highlightID: Highlight.ID
  public var originColumn: Int
  public var glyphRuns: [GlyphRun]?

  public var columnsCount: Int {
    rowPartContent.columnsCount
  }

  public var columnsRange: Range<Int> {
    originColumn ..< originColumn + columnsCount
  }

  public init(
    rowPartContent: RowPartContent,
    originColumn: Int,
    highlightID: Highlight.ID,
    font: Font,
    appearance: Appearance
  ) {
    let isBold = appearance.isBold(for: highlightID)
    let isItalic = appearance.isItalic(for: highlightID)

    let shouldUseCache: Bool =
      if case let .cells(array) = rowPartContent {
        array.count < 6
      } else {
        false
      }
    var cacheKey: Int?
    if shouldUseCache {
      var hasher = Hasher()
      hasher.combine(rowPartContent)
      hasher.combine(font)
      hasher.combine(isBold)
      hasher.combine(isItalic)
      cacheKey = hasher.finalize()
    }
    if
      let cacheKey, let cachedDrawRun = GlobalDrawRunsCache.shared.drawRun(
        for: cacheKey
      )
    {
      self = cachedDrawRun
    } else if case let .cells(cells) = rowPartContent {
      let appKitFont = font.appKit(
        isBold: isBold,
        isItalic: isItalic
      )

      let attributedString = NSAttributedString(
        string: .init(cells.map(\.character)),
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

      let xOffset = (font.cellWidth - bounds.width / Double(cells.count)) /
        2
      let yOffset = (font.cellHeight - bounds.height) / 2 + descent
      let offset = CGPoint(x: xOffset, y: yOffset)

      let ctRuns = CTLineGetGlyphRuns(ctLine) as! [CTRun]

      let glyphRuns = ctRuns
        .map { ctRun -> GlyphRun in
          let glyphCount = CTRunGetGlyphCount(ctRun)

          let glyphs =
            [CGGlyph](unsafeUninitializedCapacity: glyphCount)
          { buffer, initializedCount in
            CTRunGetGlyphs(ctRun, .init(), buffer.baseAddress!)
            initializedCount = glyphCount
          }

          let positions =
            [CGPoint](unsafeUninitializedCapacity: glyphCount)
          { buffer, initializedCount in
            CTRunGetPositions(ctRun, .init(), buffer.baseAddress!)
            initializedCount = glyphCount
          }
          .map { $0 + offset }

          let advances =
            [CGSize](unsafeUninitializedCapacity: glyphCount)
          { buffer, initializedCount in
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

      let drawRun = DrawRun(
        rowPartContent: rowPartContent,
        highlightID: highlightID,
        originColumn: originColumn,
        glyphRuns: glyphRuns
      )
      if let cacheKey {
        GlobalDrawRunsCache.shared.store(drawRun, forKey: cacheKey)
      }
      self = drawRun
    } else {
      self.init(rowPartContent: rowPartContent, highlightID: highlightID, originColumn: originColumn, glyphRuns: nil)
    }
  }

  public func drawBackground(
    to context: CGContext,
    at origin: CGPoint,
    font: Font,
    appearance: Appearance
  ) {
    let rect = CGRect(
      origin: origin,
      size: .init(
        width: Double(rowPartContent.columnsCount) * font.cellWidth,
        height: font.cellHeight
      )
    )
    context.setFillColor(appearance.backgroundColor(for: highlightID).cg)
    context.fill([rect])
  }

  public func drawForeground(
    to context: CGContext,
    at rect: CGRect,
    font: Font,
    appearance: Appearance
  ) {
    guard case let .cells(cells) = rowPartContent, let glyphRuns else {
      return
    }

    let decorations = appearance.decorations(for: highlightID)
    let specialColor = appearance.specialColor(for: highlightID)
    let specialCGColor = specialColor.cg

    context.setLineWidth(1)
    context.setStrokeColor(specialCGColor)

    if decorations.isStrikethrough {
      let strikethroughY = rect.height / 2 + rect.origin.y

      context.beginPath()
      context.move(to: .init(x: rect.minX, y: strikethroughY))
      context.addLine(to: .init(x: rect.maxX, y: strikethroughY))
      context.drawPath(using: .stroke)
    }

    let underlineY = rect.origin.y + 0.5

    if decorations.isUnderline || decorations.isUnderdashed || decorations.isUnderdotted {
      context.beginPath()
      if decorations.isUnderdashed {
        context.setLineDash(phase: 0.5, lengths: [2, 2])
      } else if decorations.isUnderdotted {
        context.setLineDash(phase: 0.5, lengths: [1, 1])
      }
      context.move(to: .init(x: rect.minX, y: underlineY))
      context.addLine(to: .init(x: rect.maxX, y: underlineY))
      context.drawPath(using: .stroke)
    } else if decorations.isUnderdouble {
      context.beginPath()
      context.move(to: .init(x: rect.minX, y: underlineY))
      context.addLine(to: .init(x: rect.maxX, y: underlineY))
      context.move(to: .init(x: rect.minX, y: underlineY + 3))
      context.addLine(to: .init(x: rect.maxX, y: underlineY + 3))
      context.drawPath(using: .stroke)
    } else if decorations.isUndercurl {
      context.beginPath()

      let widthDivider = 3

      let xStep = font.cellWidth / Double(widthDivider)
      let pointsCount = cells.count * widthDivider + 1

      let oddUnderlineY = underlineY + 3
      let evenUnderlineY = underlineY

      context.move(to: .init(x: rect.minX, y: evenUnderlineY))
      for index in 1 ..< pointsCount {
        let isEven = index.isMultiple(of: 2)

        context.addLine(
          to: .init(
            x: rect.minX + Double(index) * xStep,
            y: isEven ? evenUnderlineY : oddUnderlineY
          )
        )
      }
      context.drawPath(using: .stroke)
    }

    context.setTextDrawingMode(.fill)
    context.setFillColor(appearance.foregroundColor(for: highlightID).cg)

    for glyphRun in glyphRuns {
      context.textMatrix = glyphRun.textMatrix
      context.textPosition = rect.origin
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
    !rowPart.content.isWhitespace && rowPart.content == rowPartContent
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

  init?(
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

    var rowPartCellsCount = 0

    drawRunsLoop:
      for drawRun in rowDrawRuns[origin.row].drawRuns
    {
      if drawRun.columnsRange.contains(origin.column) {
        parentOrigin = .init(
          column: drawRun.originColumn,
          row: origin.row
        )
        parentDrawRun = drawRun
        switch drawRun.rowPartContent {
        case let .cells(cells):
          for (rowPartCellIndex, rowPartCell) in cells.enumerated() {
            let lowerBound = rowPartCellsCount + rowPartCellIndex
            let upperBound = lowerBound + (rowPartCell.isDoubleWidth ? 2 : 1)
            let range = lowerBound ..< upperBound
            if range.contains(origin.column) {
              cursorColumnsRange = range
              break drawRunsLoop
            }
          }

        case .whitespace:
          cursorColumnsRange = origin.column ..< origin.column + 1
          break drawRunsLoop
        }
        logger.fault("inconsistency error")
        break
      }

      rowPartCellsCount += drawRun.columnsCount
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
      Task { @MainActor in
        logger.fault("inconsistency error")
      }
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

  public mutating func updateParent(
    with layout: GridLayout,
    rowDrawRuns: [RowDrawRun]
  ) {
    var currentColumn = 0
    for drawRun in rowDrawRuns[origin.row].drawRuns {
      if drawRun.columnsRange.contains(origin.column) {
        parentOrigin = .init(column: currentColumn, row: origin.row)
        parentDrawRun = drawRun
      }
      currentColumn += drawRun.columnsCount
    }
  }

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

    context.setAllowsAntialiasing(false)
    context.setShouldAntialias(false)

    context.setFillColor(cursorBackgroundColor.cg)
    context.fill([rect])

    if shouldDrawParentText, let glyphRuns = parentDrawRun.glyphRuns {
      context.clip(to: [rect])

      context.setFillColor(cursorForegroundColor.cg)

      let parentRectangle = IntegerRectangle(
        origin: .init(column: parentOrigin.column, row: parentOrigin.row),
        size: .init(
          columnsCount: parentDrawRun.columnsCount,
          rowsCount: 1
        )
      )
      let parentRect = (parentRectangle * font.cellSize)
        .applying(upsideDownTransform)

      context.setAllowsAntialiasing(true)
      context.setShouldAntialias(true)

      for glyphRun in glyphRuns {
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
    }
  }
}

public final class GlobalDrawRunsCache: @unchecked Sendable {
  public static let shared = GlobalDrawRunsCache()

  private var dictionary = LockIsolated(OrderedDictionary<Int, DrawRun>())

  public func drawRun(for key: Int) -> DrawRun? {
    dictionary.withValue { dictionary in
      dictionary[key]
    }
  }

  public func store(_ drawRun: DrawRun, forKey key: Int) {
    dictionary.withValue { dictionary in
      dictionary.updateValue(drawRun, forKey: key)

      if dictionary.count > 500 {
        dictionary.removeFirst()
      }
    }
  }
}
