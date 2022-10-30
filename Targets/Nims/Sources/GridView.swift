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

class GridView: NSView, EventListener {
  init(
    frame: NSRect,
    gridID: Int,
    glyphRunsCache: Cache<String, [GlyphRun]>,
    cgColorCache: Cache<State.Color, CGColor>
  ) {
    self.gridID = gridID
    super.init(frame: frame)

    self.canDrawConcurrently = true
    self.listen()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  let gridID: Int

  override func draw(_: NSRect) {
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

        let glyphPositionsYOffset = drawingState.cellSize.height * CGFloat(drawingState.size.rowsCount - row) - drawingState.font.ascender

        let rowState = drawingState.rows[row]

        let startColumn = gridRectangle.origin.column
        let endColumn = gridRectangle.origin.column + gridRectangle.size.columnsCount - 1

        guard endColumn < rowState.highlightRuns.indexes.count, startColumn < endColumn else {
          continue
        }

        let startHighlightRunsIndex = rowState.highlightRuns.indexes[startColumn]
        let endHighlightRunIndex = rowState.highlightRuns.indexes[endColumn]

        var highlightRuns = rowState.highlightRuns.array[startHighlightRunsIndex ... endHighlightRunIndex]

        if let cursor = drawingState.cursor, cursor.position.row == row, cursor.position.column >= startColumn, cursor.position.column <= endColumn {
          highlightRuns.append(
            .init(originColumn: cursor.position.column, characters: [cursor.character], font: drawingState.font, foregroundColor: self.state.defaultHighlight.backgroundColor, backgroundColor: self.state.defaultHighlight.foregroundColor)
          )
        }

        for highlightRun in highlightRuns {
          let glyphPositionsXOffset = drawingState.cellSize.width * CGFloat(highlightRun.originColumn)

          context.saveGState()

          context.setFillColor(highlightRun.backgroundColor?.cgColor ?? .clear)
          let rect = self.cellsGeometry.upsideDownRect(
            from: self.cellsGeometry.cellsRect(
              for: .init(
                origin: .init(row: row, column: highlightRun.originColumn),
                size: .init(rowsCount: 1, columnsCount: highlightRun.columnsCount)
              )
            ),
            parentViewHeight: self.bounds.height
          )
          context.fill([rect])

          context.textMatrix = .identity
          context.setTextDrawingMode(.fill)
          context.setFillColor(highlightRun.foregroundColor?.cgColor ?? .white)

          CTFontDrawGlyphs(
            drawingState.font,
            highlightRun.glyphs,
            highlightRun.positions
              .map { .init(x: $0.x + glyphPositionsXOffset, y: $0.y + glyphPositionsYOffset) },
            highlightRun.glyphs.count,
            context
          )

          context.restoreGState()
        }
      }
    }

    context.flush()
  }

  func published(event: Event) {
    switch event {
    case .windowFrameChanged(self.gridID):
      guard self.gridID == self.gridID else {
        break
      }

      self.drawingState = nil

    case let .windowGridRowChanged(gridID, origin, columnsCount):
      guard gridID == self.gridID, var drawingState else {
        break
      }
      let state = self.state

      drawingState.rows[origin.row] = Row(gridID: gridID, state: state, row: origin.row, font: drawingState.font, cellSize: drawingState.cellSize)
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
      let state = self.state

      for rowOffset in 0 ..< rectangle.size.rowsCount {
        let row = rectangle.origin.row + rowOffset
        drawingState.rows[row] = .init(
          gridID: gridID,
          state: state,
          row: row,
          font: drawingState.font,
          cellSize: drawingState.cellSize
        )
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

      drawingState.rows = .init(
        repeating: .init(
          highlightRuns: .init(
            array: [
              .init(
                originColumn: 0,
                columnsCount: drawingState.size.columnsCount,
                glyphs: [],
                positions: [],
                advances: []
              )
            ],
            indexes: .init(
              repeating: 0,
              count: drawingState.size.columnsCount
            )
          )
        ),
        count: drawingState.size.rowsCount
      )

      self.drawingState = drawingState

      self.enqueueNeedsDisplay(self.bounds)

    case let .cursorMoved(previousCursor):
      self.drawingState?.cursor = DrawingState.makeCursor(
        gridID: self.gridID,
        state: self.state
      )

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
        let gridID = self.gridID
        let state = self.state
        guard let window = state.windows[self.gridID] else {
          break
        }
        let frame = window.frame
        let font = self.store.stateDerivatives.font.nsFont
        let cellSize = self.store.stateDerivatives.font.cellSize

        self.drawingState = DrawingState(
          rows: (0 ..< frame.size.rowsCount)
            .map { row in
              .init(
                gridID: gridID,
                state: state,
                row: row,
                font: font,
                cellSize: cellSize
              )
            },
          size: frame.size,
          font: font,
          cellSize: cellSize,
          cursor: DrawingState.makeCursor(gridID: gridID, state: state)
        )

        self.setNeedsDisplay(self.bounds)
        self.highlightChanged = false

      } else {
        for rect in self.needsDisplayBuffer {
          self.setNeedsDisplay(rect)
        }

        self.needsDisplayBuffer.removeAll(keepingCapacity: true)
      }

    default:
      break
    }
  }

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

private struct HighlightRun {
  init(originColumn: Int, columnsCount: Int, glyphs: [CGGlyph], positions: [CGPoint], advances: [CGSize], foregroundColor: State.Color? = nil, backgroundColor: State.Color? = nil) {
    self.originColumn = originColumn
    self.columnsCount = columnsCount
    self.glyphs = glyphs
    self.positions = positions
    self.advances = advances
    self.foregroundColor = foregroundColor
    self.backgroundColor = backgroundColor
  }

  init(originColumn: Int, characters: [Character], font: NSFont, foregroundColor: State.Color?, backgroundColor: State.Color?) {
    let attributedString = NSAttributedString(
      string: String(characters),
      attributes: [.font: font]
    )
    let typesetter = CTTypesetterCreateWithAttributedString(attributedString)
    let line = CTTypesetterCreateLine(typesetter, .init(location: 0, length: characters.count))

    var glyphs = [CGGlyph]()
    var positions = [CGPoint]()
    var advances = [CGSize]()

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

      advances += [CGSize](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
        CTRunGetAdvances(ctRun, range, buffer.baseAddress!)
        initializedCount = glyphCount
      }
    }

    self.init(
      originColumn: originColumn,
      columnsCount: characters.count,
      glyphs: glyphs,
      positions: positions,
      advances: advances,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor
    )
  }

  var originColumn: Int
  var columnsCount: Int

  var glyphs: [CGGlyph]
  var positions: [CGPoint]
  var advances: [CGSize]

  var foregroundColor: State.Color?
  var backgroundColor: State.Color?
}

private struct HighlightRuns {
  var array: [HighlightRun]
  var indexes: [Int]
}

private struct Row {
  init(highlightRuns: HighlightRuns) {
    self.highlightRuns = highlightRuns
  }

  init(gridID: Int, state: State, row: Int, font: NSFont, cellSize: CGSize) {
    let window = state.windows[gridID]!
    let frame = window.frame

    var totalColumnsCount = 0
    var highlightRuns = [HighlightRun]()
    var highlightRunsIndexes = [Int]()

    var latestHighlight: (characters: [Character], id: Int?)?
    func appendHighlightRun() {
      guard let (characters, id) = latestHighlight else {
        return
      }

      let highlight = id.flatMap { state.highlights[$0] } ?? state.defaultHighlight

      highlightRuns.append(
        .init(
          originColumn: totalColumnsCount,
          characters: characters,
          font: font,
          foregroundColor: highlight.reverse ? highlight.backgroundColor : highlight.foregroundColor,
          backgroundColor: highlight.reverse ? highlight.foregroundColor : highlight.backgroundColor
        )
      )

      totalColumnsCount += characters.count
    }

    for column in 0 ..< frame.size.columnsCount {
      highlightRunsIndexes.append(highlightRuns.count)

      let index = GridPoint(row: row, column: column)
      let cell = window.grid[index]
      let character = cell?.character ?? " "

      if let (characters, id) = latestHighlight {
        if id == cell?.hlID {
          latestHighlight = (characters + [character], id)
          continue

        } else {
          appendHighlightRun()
        }
      }

      latestHighlight = ([character], cell?.hlID)
    }

    appendHighlightRun()

    self.highlightRuns = .init(
      array: highlightRuns,
      indexes: highlightRunsIndexes
    )
  }

  var highlightRuns: HighlightRuns
}

private struct DrawingState {
  struct Cursor {
    var position: GridPoint
    var character: Character
    var highlight: State.Highlight
  }

  var rows: [Row]
  var size: GridSize
  var font: NSFont
  var cellSize: CGSize
  var cursor: Cursor?

  static func makeCursor(gridID: Int, state: State) -> Cursor? {
    guard let position = state.cursorPosition(gridID: gridID), let window = state.windows[gridID] else {
      return nil
    }

    return .init(
      position: position,
      character: window.grid[position]?.character ?? " ",
      highlight: state.defaultHighlight
    )
  }
}
