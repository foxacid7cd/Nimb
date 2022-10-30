//
//  GridView.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import CasePaths
import Combine
import Library
import Nvim
import RxCocoa
import RxSwift

class GridView: NSView, EventListener, CALayerDelegate {
  init(
    frame: NSRect,
    gridID: Int,
    glyphRunsCache: Cache<String, [GlyphRun]>,
    cgColorCache: Cache<State.Color, CGColor>
  ) {
    self.gridID = gridID

    let subviewFrame = NSRect(origin: .init(), size: frame.size)
    self.backgroundView = .init(frame: subviewFrame, gridID: gridID, cgColorCache: cgColorCache)
    self.foregroundView = .init(frame: subviewFrame, gridID: gridID, glyphRunsCache: glyphRunsCache, cgColorCache: cgColorCache)

    super.init(frame: frame)

    self.backgroundView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(self.backgroundView)

    self.foregroundView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(self.foregroundView)

    self.canDrawConcurrently = true

    self.listen()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  let gridID: Int

  override func layout() {
    self.backgroundView.frame.size = bounds.size
    self.foregroundView.frame.size = bounds.size
  }

  func published(event: Event) {
    switch event {
    case let .windowGridRowChanged(gridID, origin, columnsCount):
      guard gridID == self.gridID, var drawingState else {
        break
      }

      drawingState.rows[origin.row] = .init(gridID: gridID, state: self.state, row: origin.row, font: drawingState.font, cellSize: drawingState.cellSize)

      self.drawingState = drawingState

      self.enqueueNeedsDisplay(
        self.cellsGeometry.upsideDownRect(
          from: self.cellsGeometry.cellsRect(
            for: .init(
              origin: origin,
              size: .init(
                rowsCount: 1,
                columnsCount: columnsCount
              )
            )
          ),
          parentViewHeight: self.bounds.height
        )
      )

    case let .windowGridRectangleChanged(gridID, rectangle):
      guard gridID == self.gridID, var drawingState else {
        break
      }

      for row in rectangle.origin.row ..< rectangle.origin.row + rectangle.size.rowsCount {
        drawingState.rows[row] = .init(gridID: gridID, state: self.state, row: row, font: drawingState.font, cellSize: drawingState.cellSize)
      }

      self.drawingState = drawingState

      self.enqueueNeedsDisplay(
        self.cellsGeometry.upsideDownRect(
          from: self.cellsGeometry.cellsRect(for: rectangle),
          parentViewHeight: self.bounds.height
        )
      )

    case let .windowGridRectangleMoved(gridID, rectangle, toOrigin):
      guard gridID == self.gridID, var drawingState else {
        break
      }

      if rectangle.size.columnsCount == drawingState.size.columnsCount, toOrigin.column == 0 {
        let rowsCopy = drawingState.rows

        for row in rectangle.rowsRange {
          let toRow = row - rectangle.origin.row + toOrigin.row

          guard toRow >= 0, toRow < drawingState.size.rowsCount else {
            continue
          }

          drawingState.rows[toRow] = rowsCopy[row]
        }

        self.drawingState = drawingState

        let toRectangle = GridRectangle(origin: toOrigin, size: rectangle.size)
          .intersection(.init(size: drawingState.size))

        if let toRectangle {
          self.enqueueNeedsDisplay(
            self.cellsGeometry.upsideDownRect(
              from: self.cellsGeometry.cellsRect(
                for: toRectangle
              ),
              parentViewHeight: self.bounds.height
            )
          )
        }

      } else {
        assertionFailure()
      }

    case let .windowGridCleared(gridID):
      guard gridID == self.gridID, var drawingState else {
        break
      }

      drawingState.rows = .init(repeating: .init(highlightRuns: .init(array: [.init(originColumn: 0, columnsCount: drawingState.size.columnsCount, foregroundColor: self.state.defaultHighlight.foregroundColor, backgroundColor: self.state.defaultHighlight.backgroundColor)], indexes: .init(repeating: 0, count: drawingState.size.columnsCount)), glyphRuns: .init(array: [.init(originColumn: 0, columnsCount: drawingState.size.columnsCount, glyphs: [], positions: [])], indexes: .init(repeating: 0, count: drawingState.size.columnsCount))), count: drawingState.size.rowsCount)

      self.drawingState = drawingState

      self.enqueueNeedsDisplay(self.bounds)

    case let .cursorMoved(previousCursor):
      if let previousCursor, previousCursor.gridID == self.gridID {
        self.enqueueNeedsDisplay(
          self.cellsGeometry.upsideDownRect(
            from: self.cellsGeometry.cellRect(
              for: previousCursor.position
            ),
            parentViewHeight: self.bounds.height
          )
        )
      }

      if let cursor = self.state.cursor, cursor.gridID == self.gridID {
        self.enqueueNeedsDisplay(
          self.cellsGeometry.upsideDownRect(
            from: self.cellsGeometry.cellRect(
              for: cursor.position
            ),
            parentViewHeight: self.bounds.height
          )
        )
      }

    case .highlightChanged:
      self.highlightChanged = true

    case .flushRequested:
      if self.drawingState == nil || self.highlightChanged {
        let state = self.state
        let window = state.windows[self.gridID]!
        let frame = window.frame

        self.drawingState = .init(
          rows: (0 ..< frame.size.rowsCount)
            .map { row in
              Row(
                gridID: self.gridID,
                state: state,
                row: row,
                font: self.store.stateDerivatives.font.nsFont,
                cellSize: self.store.stateDerivatives.font.cellSize
              )
            },
          size: frame.size,
          font: self.store.stateDerivatives.font.nsFont,
          cellSize: self.store.stateDerivatives.font.cellSize,
          cursorPosition: {
            if let cursor = state.cursor, cursor.gridID == self.gridID {
              return cursor.position

            } else {
              return nil
            }
          }()
        )
        self.backgroundView.drawingState = self.drawingState
        self.foregroundView.drawingState = self.drawingState

        self.backgroundView.setNeedsDisplay(self.bounds)
        self.foregroundView.setNeedsDisplay(self.bounds)

        self.highlightChanged = false

      } else {
        self.backgroundView.drawingState = self.drawingState
        self.foregroundView.drawingState = self.drawingState

        for rect in self.needsDisplayBuffer {
          self.backgroundView.setNeedsDisplay(rect)
          self.foregroundView.setNeedsDisplay(
            self.cellsGeometry.insetForDrawing(rect: rect)
          )
        }

        self.needsDisplayBuffer.removeAll(keepingCapacity: true)

        DispatchQueues.SerialDrawing.async(flags: .barrier) {
          self.backgroundView.synchronizeDrawingContext = true
          self.foregroundView.synchronizeDrawingContext = true
        }
      }

    default:
      break
    }
  }

  private let backgroundView: BackgroundView
  private let foregroundView: ForegroundView
  private var needsDisplayBuffer = [CGRect]()
  private var highlightChanged = false

  private var drawingState: DrawingState?

  private var windowState: State.Window? {
    self.state.windows[self.gridID]
  }

  private var grid: Grid<Cell?>? {
    self.windowState?.grid
  }

  private var cellsGeometry: CellsGeometry {
    .shared
  }

  private func enqueueNeedsDisplay(_ rect: CGRect) {
    self.needsDisplayBuffer.append(rect)
  }
}

private class ForegroundView: NSView {
  init(
    frame: NSRect,
    gridID: Int,
    glyphRunsCache: Cache<String, [GlyphRun]>,
    cgColorCache: Cache<State.Color, CGColor>
  ) {
    self.gridID = gridID
    self.glyphRunsCache = glyphRunsCache
    self.cgColorCache = cgColorCache
    super.init(frame: frame)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func draw(_: NSRect) {
    guard let drawingState, let context = NSGraphicsContext.current?.cgContext else {
      return
    }

    context.saveGState()
    defer { context.restoreGState() }

    context.setShouldAntialias(true)
    context.setShouldSmoothFonts(true)
    context.setShouldSubpixelPositionFonts(true)
    context.setShouldSubpixelQuantizeFonts(true)

    for rect in self.rectsBeingDrawn() {
      let gridRectangle = self.cellsGeometry.gridRectangle(
        cellsRect: self.cellsGeometry.upsideDownRect(
          from: rect,
          parentViewHeight: self.bounds.height
        )
      )

      for row in gridRectangle.rowsRange {
        guard row < drawingState.size.rowsCount else {
          continue
        }

        let rowGlyphPositionsYOffset = drawingState.cellSize.height * CGFloat(drawingState.size.rowsCount - row) - drawingState.font.ascender

        let rowState = drawingState.rows[row]

        let startColumn = gridRectangle.origin.column
        let endColumn = gridRectangle.origin.column + gridRectangle.size.columnsCount - 1

        guard endColumn < rowState.glyphRuns.indexes.count, endColumn < rowState.highlightRuns.indexes.count, startColumn < endColumn else {
          continue
        }

        let startGlyphRunIndex = rowState.glyphRuns.indexes[startColumn]
        let endGlyphRunIndex = rowState.glyphRuns.indexes[endColumn]

        for glyphRunIndex in startGlyphRunIndex ... endGlyphRunIndex {
          let glyphRun = rowState.glyphRuns.array[glyphRunIndex]

          let originColumn = max(glyphRun.originColumn, gridRectangle.origin.column) - glyphRun.originColumn
          let columnsCount = min(glyphRun.columnsCount, gridRectangle.size.columnsCount) - originColumn

          guard columnsCount > 0 else {
            continue
          }

          var glyphs = [CGGlyph]()
          var positions = [CGPoint]()

          for column in 0 ..< columnsCount {
            let xOffset: CGFloat = drawingState.cellSize.width * CGFloat(column + glyphRun.originColumn)

            glyphs += glyphRun.glyphs
            positions += glyphRun.positions
              .map { CGPoint(x: $0.x + xOffset, y: $0.y + rowGlyphPositionsYOffset) }
          }

          context.saveGState()

          context.textMatrix = .identity
          context.setTextDrawingMode(.fill)
          context.setFillColor(.white)

          CTFontDrawGlyphs(
            drawingState.font,
            glyphs,
            positions,
            glyphs.count,
            context
          )

          context.restoreGState()
        }

        let startHighlightRunsIndex = rowState.highlightRuns.indexes[startColumn]
        let endHighlightRunIndex = rowState.highlightRuns.indexes[endColumn]

        for highlightRunIndex in startHighlightRunsIndex ... endHighlightRunIndex {
          let highlightRun = rowState.highlightRuns.array[highlightRunIndex]

          let originColumn = max(highlightRun.originColumn, gridRectangle.origin.column) - highlightRun.originColumn
          let columnsCount = min(highlightRun.columnsCount, gridRectangle.size.columnsCount) - originColumn

          guard columnsCount > 0 else {
            continue
          }

          context.saveGState()

          context.setBlendMode(.sourceIn)
          context.setFillColor(highlightRun.foregroundColor?.cgColor ?? .white)

          let rect = self.cellsGeometry.upsideDownRect(
            from: self.cellsGeometry.cellsRect(
              for: .init(
                origin: .init(row: row, column: originColumn),
                size: .init(rowsCount: 1, columnsCount: columnsCount)
              )
            ),
            parentViewHeight: self.bounds.height
          )
          context.fill([rect])

          context.restoreGState()
        }
      }
    }

    if self.synchronizeDrawingContext {
      context.synchronize()

      DispatchQueues.SerialDrawing.async(flags: .barrier) {
        self.synchronizeDrawingContext = false
      }
    }
  }

//        let glyphRun = rowState.glyphRuns.array[index]
//        let characters = gridRectangle.columnsRange
//          .compactMap { column -> Character? in
//            guard let cell = self.grid[.init(row: row, column: column)] else {
//              return " "
//            }
//
//            return cell.character
//          }
//        let text = String(characters)
//
//        let origin = GridPoint(row: row, column: gridRectangle.origin.column)
//        let cellsRect = self.cellsGeometry.upsideDownRect(
//          from: self.cellsGeometry.cellsRect(
//            for: .init(
//              origin: origin,
//              size: .init(
//                rowsCount: 1,
//                columnsCount: gridRectangle.size.columnsCount
//              )
//            )
//          ),
//          parentViewHeight: self.bounds.height
//        )
//
//        let glyphRuns: [GlyphRun] = {
//          if let cachedGlyphRuns = self.glyphRunsCache[text] {
//            return cachedGlyphRuns
//          }
//
//          let attributedString = NSAttributedString(
//            string: text,
//            attributes: [.font: drawingState.font]
//          )
//          let typesetter = CTTypesetterCreateWithAttributedString(attributedString)
//          let line = CTTypesetterCreateLine(typesetter, .init(location: 0, length: text.count))
//
//          let ctRuns = CTLineGetGlyphRuns(line) as! [CTRun]
//
//          let glyphRuns = ctRuns.map { ctRun in
//            let glyphCount = CTRunGetGlyphCount(ctRun)
//            let range = CFRange(location: 0, length: glyphCount)
//            let glyphs = [CGGlyph](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
//              CTRunGetGlyphs(ctRun, range, buffer.baseAddress!)
//              initializedCount = glyphCount
//            }
//            let positions = [CGPoint](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
//              CTRunGetPositions(ctRun, range, buffer.baseAddress!)
//              initializedCount = glyphCount
//            }
//            return GlyphRun(
//              glyphs: glyphs,
//              positions: positions
//            )
//          }
//
//          self.glyphRunsCache[text] = glyphRuns
//          return glyphRuns
//        }()
//
//        for glyphRun in glyphRuns {
//          context.saveGState()
//
//          context.textMatrix = .identity
//          context.setTextDrawingMode(.fill)
//          context.setFillColor(.white)
//
//          CTFontDrawGlyphs(
//            font,
//            glyphRun.glyphs,
//            glyphRun.offsetPositions(
//              dx: cellsRect.origin.x,
//              dy: cellsRect.origin.y - font.descender
//            ),
//            glyphRun.glyphs.count,
//            context
//          )
//
//          context.restoreGState()
//        }
//
//        var latestHighlight: (rectangle: GridRectangle, id: Int?)?
//        func drawHighlight() {
//          guard let (rectangle, id) = latestHighlight else {
//            return
//          }
//
//          let highlight = id.flatMap { self.state.highlights[$0] } ?? self.state.defaultHighlight
//          if let color = highlight.reverse ? highlight.backgroundColor : highlight.foregroundColor {
//            context.saveGState()
//
//            context.setBlendMode(.sourceIn)
//            context.setFillColor(self.cgColor(for: color))
//
//            let rect = self.cellsGeometry.upsideDownRect(
//              from: self.cellsGeometry.cellsRect(for: rectangle),
//              parentViewHeight: self.bounds.height
//            )
//            context.fill([rect])
//
//            context.restoreGState()
//          }
//        }
//
//        for column in gridRectangle.columnsRange {
//          let index = GridPoint(row: row, column: column)
//          let cell = self.grid[index]
//
//          let hlID: Int?
//          if let cell, cell.character != " " {
//            hlID = cell.hlID
//          } else {
//            hlID = nil
//          }
//
//          if let (rectangle, id) = latestHighlight {
//            if id == hlID {
//              var newRectangle = rectangle
//              newRectangle.size.columnsCount += 1
//              latestHighlight = (newRectangle, id)
//              continue
//
//            } else {
//              drawHighlight()
//            }
//          }
//
//          let rectangle = GridRectangle(
//            origin: .init(row: row, column: column),
//            size: .init(rowsCount: 1, columnsCount: 1)
//          )
//          latestHighlight = (rectangle, hlID)
//        }
//
//        drawHighlight()
//
//        if let cursorPosition, cursorPosition.row == row, gridRectangle.columnsRange.contains(cursorPosition.column), let color = self.state.defaultHighlight.backgroundColor {
//          context.saveGState()
//          context.setFillColor(self.cgColor(for: color))
//          context.setBlendMode(.sourceIn)
//
//          let rect = self.cellsGeometry.upsideDownRect(
//            from: self.cellsGeometry.cellRect(
//              for: cursorPosition
//            ),
//            parentViewHeight: self.bounds.height
//          )
//          context.fill([rect])
//
//          context.restoreGState()
//        }
//      }
//    }

//    if self.synchronizeDrawingContext {
//      context.synchronize()
//
//      DispatchQueues.SerialDrawing.async(flags: .barrier) {
//        self.synchronizeDrawingContext = false
//      }
//    }
//  }

  var drawingState: DrawingState?
  var synchronizeDrawingContext = false

  private let gridID: Int
  private let glyphRunsCache: Cache<String, [GlyphRun]>
  private let cgColorCache: Cache<State.Color, CGColor>

  private var windowState: State.Window? {
    self.state.windows[self.gridID]
  }

  private var grid: Grid<Cell?>? {
    self.windowState?.grid
  }

  private var cellsGeometry: CellsGeometry {
    .shared
  }

  private func cgColor(for color: State.Color) -> CGColor {
    if let cachedCGColor = self.cgColorCache[color] {
      return cachedCGColor
    }

    let cgColor = color.cgColor
    self.cgColorCache[color] = cgColor
    return cgColor
  }
}

private class BackgroundView: NSView {
  init(
    frame: NSRect,
    gridID: Int,
    cgColorCache: Cache<State.Color, CGColor>
  ) {
    self.gridID = gridID
    self.cgColorCache = cgColorCache
    super.init(frame: frame)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func draw(_: NSRect) {
    guard let drawingState, let context = NSGraphicsContext.current?.cgContext else {
      return
    }

    context.saveGState()
    defer { context.restoreGState() }

    for rect in self.rectsBeingDrawn() {
      let gridRectangle = self.cellsGeometry.gridRectangle(
        cellsRect: self.cellsGeometry.upsideDownRect(
          from: rect,
          parentViewHeight: self.bounds.height
        )
      )

      for row in gridRectangle.rowsRange {
        guard row < drawingState.size.rowsCount else {
          continue
        }

        let rowState = drawingState.rows[row]

        let startColumn = gridRectangle.origin.column
        let endColumn = gridRectangle.origin.column + gridRectangle.size.columnsCount - 1

        guard endColumn < rowState.highlightRuns.indexes.count, startColumn < endColumn else {
          continue
        }

        let startHighlightRunsIndex = rowState.highlightRuns.indexes[startColumn]
        let endHighlightRunIndex = rowState.highlightRuns.indexes[endColumn]

        for highlightRunIndex in startHighlightRunsIndex ... endHighlightRunIndex {
          let highlightRun = rowState.highlightRuns.array[highlightRunIndex]

          let originColumn = max(highlightRun.originColumn, gridRectangle.origin.column) - highlightRun.originColumn
          let columnsCount = min(highlightRun.columnsCount, gridRectangle.size.columnsCount) - originColumn

          guard columnsCount > 0 else {
            continue
          }

          context.saveGState()

          context.setFillColor(highlightRun.backgroundColor?.cgColor ?? .clear)

          let rect = self.cellsGeometry.upsideDownRect(
            from: self.cellsGeometry.cellsRect(
              for: .init(
                origin: .init(row: row, column: originColumn),
                size: .init(rowsCount: 1, columnsCount: columnsCount)
              )
            ),
            parentViewHeight: self.bounds.height
          )
          context.fill([rect])

          context.restoreGState()
        }
      }
    }

    if self.synchronizeDrawingContext {
      context.synchronize()

      DispatchQueues.SerialDrawing.async(flags: .barrier) {
        self.synchronizeDrawingContext = false
      }
    }
  }

  var synchronizeDrawingContext = false

  var drawingState: DrawingState?

  private let gridID: Int
  private let cgColorCache: Cache<State.Color, CGColor>

  private var windowState: State.Window {
    self.state.windows[self.gridID]!
  }

  private var grid: Grid<Cell?> {
    self.windowState.grid
  }

  private var cellsGeometry: CellsGeometry {
    .shared
  }

  private func cgColor(for color: State.Color) -> CGColor {
    if let cachedCGColor = self.cgColorCache[color] {
      return cachedCGColor
    }

    let cgColor = color.cgColor
    self.cgColorCache[color] = cgColor
    return cgColor
  }
}

private struct HighlightRun {
  var originColumn: Int
  var columnsCount: Int

  var foregroundColor: State.Color?
  var backgroundColor: State.Color?
}

private struct HighlightRuns {
  var array: [HighlightRun]
  var indexes: [Int]
}

private struct _GlyphRun {
  var originColumn: Int
  var columnsCount: Int

  var glyphs: [CGGlyph]
  var positions: [CGPoint]
}

private struct GlyphRuns {
  var array: [_GlyphRun]
  var indexes: [Int]
}

private struct Row {
  init(highlightRuns: HighlightRuns, glyphRuns: GlyphRuns) {
    self.highlightRuns = highlightRuns
    self.glyphRuns = glyphRuns
  }

  init(gridID: Int, state: State, row: Int, font: NSFont, cellSize: CGSize) {
    let window = state.windows[gridID]!
    let frame = window.frame

    var totalColumnsCount = 0
    var highlightRuns = [HighlightRun]()
    var highlightRunsIndexes = [Int]()

    var latestHighlight: (columnsCount: Int, id: Int?)?
    func appendHighlightRun() {
      guard let (columnsCount, id) = latestHighlight else {
        return
      }

      let highlight = id.flatMap { state.highlights[$0] } ?? state.defaultHighlight
      highlightRuns.append(
        .init(
          originColumn: totalColumnsCount,
          columnsCount: columnsCount,
          foregroundColor: highlight.reverse ? highlight.backgroundColor : highlight.foregroundColor,
          backgroundColor: highlight.reverse ? highlight.foregroundColor : highlight.backgroundColor
        )
      )

      totalColumnsCount += columnsCount
    }

    for column in 0 ..< frame.size.columnsCount {
      highlightRunsIndexes.append(highlightRuns.count)

      let index = GridPoint(row: row, column: column)
      let cell = window.grid[index]

      if let (columnsCount, id) = latestHighlight {
        if id == cell?.hlID {
          latestHighlight = (columnsCount + 1, id)
          continue

        } else {
          appendHighlightRun()
        }
      }

      latestHighlight = (1, cell?.hlID)
    }

    appendHighlightRun()

    var totalGlyphRunsCount = 0
    var glyphRuns = [_GlyphRun]()
    var glyphRunsIndexes = [Int]()

    var latestGlyphRun: (columnsCount: Int, character: Character)?
    func appendGlyphRun() {
      guard let (columnsCount, character) = latestGlyphRun else {
        return
      }

      let attributedString = NSAttributedString(
        string: String(character),
        attributes: [.font: font]
      )
      let typesetter = CTTypesetterCreateWithAttributedString(attributedString)
      let line = CTTypesetterCreateLine(typesetter, .init(location: 0, length: 1))

      var glyphs = [CGGlyph]()
      var positions = [CGPoint]()

      let ctRuns = CTLineGetGlyphRuns(line) as! [CTRun]
      for ctRun in ctRuns {
        let glyphCount = CTRunGetGlyphCount(ctRun)
        let range = CFRange(location: 0, length: glyphCount)

        glyphs += [CGGlyph](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
          CTRunGetGlyphs(ctRun, range, buffer.baseAddress!)
          initializedCount = glyphCount
        }

        positions += [CGPoint](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
          CTRunGetPositions(ctRun, range, buffer.baseAddress!)
          initializedCount = glyphCount
        }
      }

      glyphRuns.append(
        .init(
          originColumn: totalGlyphRunsCount,
          columnsCount: columnsCount,
          glyphs: glyphs,
          positions: positions
        )
      )

      totalGlyphRunsCount += columnsCount
    }

    for column in 0 ..< frame.size.columnsCount {
      glyphRunsIndexes.append(glyphRuns.count)

      let index = GridPoint(row: row, column: column)
      let cell = window.grid[index]
      let cellCharacter = cell?.character ?? " "

      if let (columnsCount, character) = latestGlyphRun {
        if character == cellCharacter {
          latestGlyphRun = (columnsCount + 1, character)
          continue

        } else {
          appendGlyphRun()
        }
      }

      latestGlyphRun = (1, cellCharacter)
    }

    appendGlyphRun()

    self.init(
      highlightRuns: .init(array: highlightRuns, indexes: highlightRunsIndexes),
      glyphRuns: .init(array: glyphRuns, indexes: glyphRunsIndexes)
    )
  }

  var highlightRuns: HighlightRuns
  var glyphRuns: GlyphRuns
}

private struct DrawingState {
  var rows: [Row]
  var size: GridSize
  var font: NSFont
  var cellSize: CGSize
  var cursorPosition: GridPoint?
}
