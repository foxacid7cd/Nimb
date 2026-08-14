// SPDX-License-Identifier: MIT

import AppKit
import Collections
import NimbCore
import SwiftUI
import Synchronization

@PublicInit
public struct GridDrawRuns: Sendable {
  public struct VisibleDrawRun {
    public let drawRun: DrawRun
    public let rect: CGRect
  }

  public struct VisibleRowDrawRun {
    public let drawRuns: [VisibleDrawRun]
  }

  public var rowDrawRuns: [RowDrawRun]
  public var cursorDrawRun: CursorDrawRun? = nil

  public init(
    layout: GridLayout,
    font: Font,
    appearance: Appearance,
  ) {
    rowDrawRuns = []
    renderDrawRuns(for: layout, font: font, appearance: appearance)
  }

  /// Set reusingOld to false to reshape everything from scratch. Reuse checks
  /// content and the bold/italic traits but not the font, so a font change has
  /// to bypass it wholesale.
  public mutating func renderDrawRuns(
    for layout: GridLayout,
    font: Font,
    appearance: Appearance,
    reusingOld: Bool = true,
  ) {
    rowDrawRuns = layout.rowLayouts
      .enumerated()
      .map { row, layout in
        .init(
          row: row,
          layout: layout,
          font: font,
          appearance: appearance,
          old: reusingOld && row < rowDrawRuns.count ? rowDrawRuns[row] : nil,
        )
      }
  }

  public func drawBackground(
    to context: CGContext,
    boundingRect: IntegerRectangle,
    font: Font,
    appearance: Appearance,
    upsideDownTransform: CGAffineTransform,
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
        upsideDownTransform: upsideDownTransform,
      )
    }
  }

  public func drawForeground(
    to context: CGContext,
    boundingRect: IntegerRectangle,
    font: Font,
    appearance: Appearance,
    upsideDownTransform: CGAffineTransform,
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
        upsideDownTransform: upsideDownTransform,
      )
    }
  }

  public func visibleRowDrawRuns(
    boundingRect: IntegerRectangle,
    font: Font,
    upsideDownTransform: CGAffineTransform,
  )
  -> [VisibleRowDrawRun] {
    let fromRow = max(boundingRect.minRow, 0)
    let toRow = min(boundingRect.maxRow, rowDrawRuns.count)
    guard fromRow < toRow else {
      return []
    }

    return (fromRow ..< toRow).compactMap { row in
      let drawRuns = rowDrawRuns[row].visibleDrawRuns(
        columnsRange: boundingRect.columns,
        at: .init(x: 0, y: Double(row) * font.cellHeight),
        font: font,
        upsideDownTransform: upsideDownTransform,
      )
      guard !drawRuns.isEmpty else {
        return nil
      }
      return VisibleRowDrawRun(drawRuns: drawRuns)
    }
  }
}

@PublicInit
public struct RowDrawRun: Sendable {
  public var drawRuns: [DrawRun]

  public init(
    row: Int,
    layout: RowLayout,
    font: Font,
    appearance: Appearance,
    old: RowDrawRun?,
  ) {
    var drawRuns = [DrawRun]()
    drawRuns.reserveCapacity(layout.parts.count)

    for (index, part) in layout.parts.enumerated() {
      // Reuse is index-aligned against the previous version of this row, which
      // covers the case that matters: the row did not change.
      //
      // There used to be a per-row dictionary keyed by content as well, which
      // meant hashing every part's characters twice per update -- once to look
      // it up, once to insert -- and hashing a run of Characters goes through
      // String hashing, so it was not cheap. GlobalDrawRunsCache now covers
      // content reuse across the whole grid rather than within a single row,
      // so the per-row copy earned nothing.
      var drawRun: DrawRun =
        if
          let old, index < old.drawRuns.endIndex,
          old.drawRuns[index].shouldBeReused(for: part, appearance: appearance)
        {
          old.drawRuns[index]
        } else {
          DrawRun(
            rowPartContent: part.content,
            originColumn: part.originColumn,
            highlightID: part.highlightID,
            font: font,
            appearance: appearance,
          )
        }
      drawRun.originColumn = part.originColumn
      drawRun.highlightID = part.highlightID
      drawRuns.append(drawRun)
    }

    self.drawRuns = drawRuns
  }

  public func drawBackground(
    columnsRange: Range<Int>,
    at origin: CGPoint,
    to context: CGContext,
    font: Font,
    appearance: Appearance,
    upsideDownTransform: CGAffineTransform,
  ) {
    for drawRun in drawRuns where drawRun.columnsRange.overlaps(columnsRange) {
      let rect = CGRect(
        x: Double(drawRun.columnsRange.lowerBound) * font.cellWidth + origin.x,
        y: origin.y,
        width: Double(drawRun.columnsRange.count) * font.cellWidth,
        height: font.cellHeight,
      )
      .applying(upsideDownTransform)

      drawRun.drawBackground(
        to: context,
        at: rect.origin,
        font: font,
        appearance: appearance,
      )
    }
  }

  public func drawForeground(
    columnsRange: Range<Int>,
    at origin: CGPoint,
    to context: CGContext,
    font: Font,
    appearance: Appearance,
    upsideDownTransform: CGAffineTransform,
  ) {
    for drawRun in drawRuns where drawRun.columnsRange.overlaps(columnsRange) {
      let rect = CGRect(
        x: Double(drawRun.columnsRange.lowerBound) * font.cellWidth + origin.x,
        y: origin.y,
        width: Double(drawRun.columnsRange.count) * font.cellWidth,
        height: font.cellHeight,
      )
      .applying(upsideDownTransform)

      drawRun.drawForeground(
        to: context,
        at: rect,
        font: font,
        appearance: appearance,
      )
    }
  }

  func visibleDrawRuns(
    columnsRange: Range<Int>,
    at origin: CGPoint,
    font: Font,
    upsideDownTransform: CGAffineTransform,
  )
  -> [GridDrawRuns.VisibleDrawRun] {
    drawRuns.compactMap { drawRun in
      guard drawRun.columnsRange.overlaps(columnsRange) else {
        return nil
      }

      let rect = CGRect(
        x: Double(drawRun.columnsRange.lowerBound) * font.cellWidth + origin.x,
        y: origin.y,
        width: Double(drawRun.columnsRange.count) * font.cellWidth,
        height: font.cellHeight,
      )
      .applying(upsideDownTransform)

      return .init(drawRun: drawRun, rect: rect)
    }
  }
}

@PublicInit
public struct DrawRun: Sendable {
  /// Runs longer than this are shaped every time. Long runs are both less
  /// likely to recur verbatim and more expensive to keep, so they are not
  /// worth a cache slot.
  private static let maxCachedCellsCount = 64

  public var rowPartContent: RowPartContent
  public var highlightID: Highlight.ID
  public var originColumn: Int
  public var glyphRuns: [GlyphRun]? = nil
  /// What the glyphs were shaped for, so reuse can tell whether they still
  /// apply. Defaulted because the whitespace case draws no glyphs at all.
  public var isBold: Bool = false
  public var isItalic: Bool = false

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
    appearance: Appearance,
  ) {
    let isBold = appearance.isBold(for: highlightID)
    let isItalic = appearance.isItalic(for: highlightID)

    // Cache any run that fits. The miss path below builds an NSAttributedString
    // and runs CoreText typesetting, which profiling put at 12% of the app's
    // CPU under load. The previous limit of six cells excluded most real
    // tokens -- "return" and "context" reshaped on every single occurrence,
    // even though a code buffer repeats the same identifiers constantly.
    let cacheKey: GlobalDrawRunsCache.Key? =
      if case let .cells(cells) = rowPartContent, cells.count <= Self.maxCachedCellsCount {
        .init(content: rowPartContent, font: font, isBold: isBold, isItalic: isItalic)
      } else {
        nil
      }
    if let cacheKey, let cachedDrawRun = GlobalDrawRunsCache.shared.drawRun(for: cacheKey) {
      // originColumn and highlightID are overwritten by the caller, and the
      // glyphs depend only on what the key covers, so sharing is safe.
      self = cachedDrawRun
    } else if case let .cells(cells) = rowPartContent {
      let appKitFont = font.appKit(
        isBold: isBold,
        isItalic: isItalic,
      )

      let attributedString = NSAttributedString(
        string: .init(cells.map(\.character)),
        attributes: [.font: appKitFont],
      )

      let ctTypesetter = CTTypesetterCreateWithAttributedStringAndOptions(
        attributedString,
        nil,
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
            advances: advances,
          )
        }

      let drawRun = DrawRun(
        rowPartContent: rowPartContent,
        highlightID: highlightID,
        originColumn: originColumn,
        glyphRuns: glyphRuns,
        isBold: isBold,
        isItalic: isItalic,
      )
      if let cacheKey {
        GlobalDrawRunsCache.shared.store(drawRun, forKey: cacheKey)
      }
      self = drawRun
    } else {
      self.init(
        rowPartContent: rowPartContent,
        highlightID: highlightID,
        originColumn: originColumn,
        glyphRuns: nil,
        isBold: isBold,
        isItalic: isItalic,
      )
    }
  }

  public func drawBackground(
    to context: CGContext,
    at origin: CGPoint,
    font: Font,
    appearance: Appearance,
  ) {
    let rect = CGRect(
      origin: origin,
      size: .init(
        width: Double(rowPartContent.columnsCount) * font.cellWidth,
        height: font.cellHeight,
      ),
    )
    context.setFillColor(appearance.backgroundColor(for: highlightID).cg)
    context.fill([rect])
  }

  public func drawForeground(
    to context: CGContext,
    at rect: CGRect,
    font: Font,
    appearance: Appearance,
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
            y: isEven ? evenUnderlineY : oddUnderlineY,
          ),
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
        context,
      )
    }
  }

  public func shouldBeReused(for rowPart: RowPart, appearance: Appearance) -> Bool {
    guard !rowPart.content.isWhitespace, rowPart.content == rowPartContent else {
      return false
    }
    // Glyphs are shaped for a specific weight and slant, so a part whose text
    // is unchanged still has to be reshaped when its highlight turns bold or
    // italic. This used to compare content alone; a row keeping its text while
    // changing highlight -- entering visual mode, say -- kept the old glyphs.
    return isBold == appearance.isBold(for: rowPart.highlightID)
      && isItalic == appearance.isItalic(for: rowPart.highlightID)
  }
}

/// Unchecked only because of `appKitFont: NSFont`, which is immutable and
/// documented as thread safe but is not annotated Sendable. Everything else
/// here is a value type.
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
        rowsCount: 1,
      ),
    )
  }

  init?(
    layout: GridLayout,
    rowDrawRuns: [RowDrawRun],
    origin: IntegerPoint,
    columnsCount: Int,
    style: CursorStyle,
    font: Font,
    appearance: Appearance,
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
          row: origin.row,
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
        font: font,
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
      shouldDrawParentText: style.shouldDrawParentText,
    )
  }

  public mutating func updateParent(
    with layout: GridLayout,
    rowDrawRuns: [RowDrawRun],
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
    upsideDownTransform: CGAffineTransform,
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
          rowsCount: 1,
        ),
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
          context,
        )
      }
    }
  }
}

public final class GlobalDrawRunsCache: Sendable {
  /// The full identity of a shaped run. This used to be a bare Hasher output,
  /// so two different runs sharing a hash would silently render each other's
  /// glyphs; letting Dictionary compare real keys removes that failure mode,
  /// which matters more now that the cache holds far more entries.
  public struct Key: Hashable, Sendable {
    public var content: RowPartContent
    public var font: Font
    public var isBold: Bool
    public var isItalic: Bool

    public init(content: RowPartContent, font: Font, isBold: Bool, isItalic: Bool) {
      self.content = content
      self.font = font
      self.isBold = isBold
      self.isItalic = isItalic
    }
  }

  /// Two generations rather than a true LRU: insertion, lookup and eviction
  /// are all O(1), where evicting the oldest entry of an ordered dictionary
  /// shifts every element that follows it. Anything used during the current
  /// generation is promoted into it and so survives the next rollover.
  private struct Storage {
    var current: [Key: DrawRun] = [:]
    var previous: [Key: DrawRun] = [:]

    mutating func insert(_ drawRun: DrawRun, forKey key: Key) {
      current[key] = drawRun
      if current.count > GlobalDrawRunsCache.capacity {
        previous = current
        current = [:]
      }
    }
  }

  public static let shared = GlobalDrawRunsCache()

  /// Per generation, so the resident set is at most twice this.
  private static let capacity = 4096

  private let storage = Mutex(Storage())

  public func drawRun(for key: Key) -> DrawRun? {
    storage.withLock { storage in
      if let drawRun = storage.current[key] {
        return drawRun
      }
      guard let drawRun = storage.previous[key] else {
        return nil
      }
      storage.insert(drawRun, forKey: key)
      return drawRun
    }
  }

  public func store(_ drawRun: DrawRun, forKey key: Key) {
    storage.withLock { storage in
      storage.insert(drawRun, forKey: key)
    }
  }
}
