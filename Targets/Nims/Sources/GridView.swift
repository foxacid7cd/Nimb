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
    gridID: Int
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
    let state = self.state

    context.saveGState()
    defer { context.restoreGState() }

    context.setShouldAntialias(true)
    context.setShouldSmoothFonts(true)
    context.setShouldSubpixelPositionFonts(true)
    context.setShouldSubpixelQuantizeFonts(true)

    let rects = self.rectsBeingDrawn()

    context.setFillColor(drawingState.backgroundColor)
    context.fill(rects)

    var drawRuns = [DrawRun]()

    for rect in rects {
      let rectangle = self.cellsGeometry.gridRectangle(
        cellsRect: self.cellsGeometry.upsideDownRect(
          from: rect,
          parentViewHeight: self.bounds.height
        )
      )

      for row in rectangle.rowsRange {
        var glyphsInRowCount = 0

        var latestHighlight: (characters: [Character], id: Int?)?
        func createDrawRun() {
          guard let (characters, id) = latestHighlight else {
            return
          }

          let highlight = id.flatMap { state.highlights[$0] } ?? state.defaultHighlight
          let foregroundColor = highlight.foregroundColor?.cgColor ?? .white
          let backgroundColor = highlight.backgroundColor?.cgColor ?? .clear

          let origin = GridPoint(row: row, column: glyphsInRowCount)

          let drawRun: DrawRun
          if let cachedGlyphRun = drawingState.glyphRunCache[characters] {
            drawRun = DrawRun(
              origin: origin,
              characters: characters,
              glyphRun: cachedGlyphRun,
              foregroundColor: foregroundColor,
              backgroundColor: backgroundColor
            )

          } else {
            let newDrawRun = DrawRun.make(
              origin: origin,
              characters: characters,
              font: drawingState.font,
              foregroundColor: foregroundColor,
              backgroundColor: backgroundColor
            )
            drawingState.glyphRunCache[characters] = newDrawRun.glyphRun
            drawRun = newDrawRun
          }

          drawRuns.append(drawRun)

          glyphsInRowCount += drawRun.glyphRun.glyphs.count
        }

        for column in 0 ..< drawingState.grid.size.columnsCount {
          let index = GridPoint(row: row, column: column)
          let cell = drawingState.grid[index]
          let newCharacters: [Character]
          if let cell {
            if let cellCharacter = cell.character {
              newCharacters = [cellCharacter]

            } else {
              newCharacters = []
            }

          } else {
            newCharacters = [" "]
          }

          if let (characters, id) = latestHighlight {
            if id == cell?.hlID {
              latestHighlight = (characters + newCharacters, id)
              continue

            } else {
              createDrawRun()
            }
          }

          latestHighlight = (newCharacters, cell?.hlID)
        }

        createDrawRun()
      }
    }

    for drawRun in drawRuns {
      context.saveGState()

      context.setFillColor(drawRun.backgroundColor)

      let rectangle = GridRectangle(
        origin: drawRun.origin,
        size: .init(rowsCount: 1, columnsCount: drawRun.glyphRun.glyphs.count)
      )
      let rect = self.cellsGeometry.upsideDownRect(
        from: self.cellsGeometry.cellsRect(
          for: rectangle
        ),
        parentViewHeight: self.bounds.height
      )
      context.fill([rect])

      context.textMatrix = .identity
      context.setTextDrawingMode(.fill)
      context.setFillColor(drawRun.foregroundColor)

      let glyphRun = drawRun.glyphRun

      CTFontDrawGlyphs(
        glyphRun.font,
        glyphRun.glyphs,
        glyphRun.positionsWithOffset(
          dx: drawingState.cellSize.width * CGFloat(drawRun.origin.column),
          dy: drawingState.cellSize.height * CGFloat(drawingState.grid.size.rowsCount - drawRun.origin.row) - drawingState.font.ascender
        ),
        glyphRun.glyphs.count,
        context
      )

      context.restoreGState()
    }

    if let cursor = drawingState.cursor {
      context.setFillColor(.white)
      context.setBlendMode(.exclusion)

      let rect = self.cellsGeometry.upsideDownRect(
        from: self.cellsGeometry.cellRect(
          for: cursor.position
        ),
        parentViewHeight: self.bounds.height
      )
      context.fill([rect])
    }
  }

  func published(event: Event) {
    switch event {
    case let .windowFrameChanged(gridID):
      guard gridID == self.gridID else {
        break
      }

      self.drawingState = nil

    case let .windowGridRowChanged(gridID, origin, columnsCount):
      guard gridID == self.gridID, let window = self.state.windows[gridID], var drawingState else {
        break
      }

      drawingState.grid = window.grid
      self.drawingState = drawingState

      self.setNeedsDisplay(
        self.cellsGeometry.insetForDrawing(
          rect: self.cellsGeometry.upsideDownRect(
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
      )

    case let .windowGridRectangleChanged(gridID, rectangle):
      guard gridID == self.gridID, let window = self.state.windows[gridID], var drawingState else {
        break
      }

      drawingState.grid = window.grid
      self.drawingState = drawingState

      self.setNeedsDisplay(
        self.cellsGeometry.insetForDrawing(
          rect: self.cellsGeometry.upsideDownRect(
            from: self.cellsGeometry.cellsRect(for: rectangle),
            parentViewHeight: self.bounds.height
          )
        )
      )

    case let .windowGridRectangleMoved(gridID, rectangle, toOrigin):
      guard gridID == self.gridID, let window = self.state.windows[gridID], var drawingState else {
        break
      }

      drawingState.grid = window.grid
      self.drawingState = drawingState

      let toRectangle = GridRectangle(origin: toOrigin, size: rectangle.size)
        .intersection(.init(size: window.grid.size))

      if let toRectangle {
        self.setNeedsDisplay(
          self.cellsGeometry.insetForDrawing(
            rect: self.cellsGeometry.upsideDownRect(
              from: self.cellsGeometry.cellsRect(
                for: toRectangle
              ),
              parentViewHeight: self.bounds.height
            )
          )
        )
      }

    case let .windowGridCleared(gridID):
      guard gridID == self.gridID, let window = self.state.windows[gridID], var drawingState else {
        break
      }

      drawingState.grid = window.grid
      self.drawingState = drawingState

      self.setNeedsDisplay(self.bounds)

    case let .cursorMoved(previousCursor):
      self.drawingState?.cursor = DrawingState.makeCursor(
        gridID: self.gridID,
        state: self.state
      )

      if let previousCursor, previousCursor.gridID == self.gridID {
        self.setNeedsDisplay(
          self.cellsGeometry.upsideDownRect(
            from: self.cellsGeometry.cellRect(
              for: previousCursor.position
            ),
            parentViewHeight: self.bounds.height
          )
        )
      }

      if let cursor = self.state.cursor, cursor.gridID == self.gridID {
        self.setNeedsDisplay(
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
        let font = self.store.stateDerivatives.font.nsFont
        let cellSize = self.store.stateDerivatives.font.cellSize

        self.drawingState = DrawingState(
          grid: window.grid,
          font: font,
          cellSize: cellSize,
          glyphRunCache: self.store.stateDerivatives.font.glyphRunsCache,
          cursor: DrawingState.makeCursor(gridID: gridID, state: state),
          backgroundColor: state.defaultHighlight.backgroundColor?.cgColor ?? .clear
        )

        self.setNeedsDisplay(self.bounds)
        self.highlightChanged = false
      }

    default:
      break
    }
  }

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
}

private struct DrawingState {
  struct Cursor {
    var position: GridPoint
    var character: Character
    var highlight: State.Highlight
  }

  var grid: CellGrid
  var font: NSFont
  var cellSize: CGSize
  var glyphRunCache: Cache<[Character], GlyphRun>
  var cursor: Cursor?
  var backgroundColor: CGColor

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
