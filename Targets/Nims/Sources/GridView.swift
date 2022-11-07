//
//  GridView.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import API
import AppKit
import CasePaths
import Combine
import Library
import RxCocoa
import RxSwift

class GridView: NSView {
  init(
    frame: NSRect,
    gridID: Int
  ) {
    self.gridID = gridID
    super.init(frame: frame)

    self.canDrawConcurrently = true
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  let gridID: Int

  override var isOpaque: Bool {
    true
  }

  override func draw(_: NSRect) {
    guard let context = NSGraphicsContext.current else {
      return
    }

    context.saveGraphicsState()
    defer { context.restoreGraphicsState() }

    let bounds = self.bounds
    let state = self.state
    let window = state.windows[self.gridID]!
    let fontDerivatives = self.store.stateDerivatives.font

    let rects = self.rectsBeingDrawn()

    context.cgContext.setFillColor(state.defaultHighlight.backgroundColor?.cgColor ?? .clear)
    context.cgContext.fill(rects)

    var drawRuns = [DrawRun]()

    for rect in rects {
      let rectangle = self.cellsGeometry.gridRectangle(
        cellsRect: self.cellsGeometry.upsideDownRect(
          from: rect,
          parentViewHeight: bounds.height
        )
      )

      for row in rectangle.rowsRange {
        guard row < window.grid.size.rowsCount else {
          continue
        }

        var glyphsInRowCount = 0

        var latestHighlightCharacters = [Character]()
        var latestHighlightId: Int?
        func createDrawRun() {
          guard let id = latestHighlightId else {
            return
          }

          let highlight = state.highlights[id] ?? state.defaultHighlight
          let foregroundColor = highlight.foregroundColor?.cgColor ?? .white
          let backgroundColor = highlight.backgroundColor?.cgColor ?? .clear

          let font: NSFont
          let fontIdentifier: String

          if highlight.bold {
            if highlight.italic {
              font = fontDerivatives.boldItalic
              fontIdentifier = "boldItalic"

            } else {
              font = fontDerivatives.bold
              fontIdentifier = "bold"
            }
          } else {
            if highlight.italic {
              font = fontDerivatives.italic
              fontIdentifier = "italic"

            } else {
              font = fontDerivatives.regular
              fontIdentifier = "regular"
            }
          }

          var hasher = Hasher()
          hasher.combine(latestHighlightCharacters)
          hasher.combine(fontIdentifier)
          let glyphRunCacheKey = hasher.finalize()

          let origin = GridPoint(row: row, column: rectangle.origin.column + glyphsInRowCount)

          let drawRun: DrawRun
          if let cachedGlyphRun = fontDerivatives.glyphRunCache.value(forKey: glyphRunCacheKey) {
            drawRun = DrawRun(
              origin: origin,
              characters: latestHighlightCharacters,
              glyphRun: cachedGlyphRun,
              foregroundColor: foregroundColor,
              backgroundColor: backgroundColor
            )

          } else {
            let newDrawRun = DrawRun.make(
              origin: origin,
              characters: latestHighlightCharacters,
              font: font,
              foregroundColor: foregroundColor,
              backgroundColor: backgroundColor
            )
            fontDerivatives.glyphRunCache.set(value: newDrawRun.glyphRun, forKey: glyphRunCacheKey)
            drawRun = newDrawRun
          }

          drawRuns.append(drawRun)

          glyphsInRowCount += drawRun.glyphRun.glyphs.count
        }

        for column in rectangle.columnsRange {
          guard column < window.grid.size.columnsCount else {
            continue
          }

          let index = GridPoint(row: row, column: column)
          let cell = window.grid[index]
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

          if let id = latestHighlightId {
            if id == cell?.hlID {
              latestHighlightCharacters += newCharacters
              continue

            } else {
              createDrawRun()
            }
          }

          latestHighlightId = cell?.hlID
          latestHighlightCharacters = newCharacters
        }

        createDrawRun()
      }
    }

    for drawRun in drawRuns {
      context.cgContext.setFillColor(drawRun.backgroundColor)

      let rectangle = GridRectangle(
        origin: drawRun.origin,
        size: .init(rowsCount: 1, columnsCount: drawRun.glyphRun.glyphs.count)
      )
      let rect = self.cellsGeometry.upsideDownRect(
        from: self.cellsGeometry.cellsRect(
          for: rectangle
        ),
        parentViewHeight: bounds.height
      )
      context.cgContext.fill([rect])

      context.cgContext.textMatrix = .identity
      context.cgContext.setTextDrawingMode(.fill)
      context.cgContext.setFillColor(drawRun.foregroundColor)

      let glyphRun = drawRun.glyphRun

      CTFontDrawGlyphs(
        glyphRun.font,
        glyphRun.glyphs,
        glyphRun.positionsWithOffset(
          dx: fontDerivatives.cellSize.width * CGFloat(drawRun.origin.column),
          dy: fontDerivatives.cellSize.height * CGFloat(window.grid.size.rowsCount - drawRun.origin.row) - drawRun.glyphRun.font.ascender
        ),
        glyphRun.glyphs.count,
        context.cgContext
      )
    }

    if let cursorPosition = state.cursorPosition(gridID: self.gridID) {
      context.cgContext.setFillColor(state.defaultHighlight.foregroundColor?.cgColor ?? .white)
      context.cgContext.setBlendMode(.exclusion)

      let rect = self.cellsGeometry.upsideDownRect(
        from: self.cellsGeometry.cellRect(
          for: cursorPosition
        ),
        parentViewHeight: bounds.height
      )
      context.cgContext.fill([rect])
    }

    if self.needsSynchronization {
      DispatchQueues.GridViewSynchronization.dispatchQueue.async(flags: .barrier) {
        self.needsSynchronization = false
      }

      context.cgContext.flush()
    }
  }

  func setNeedsDrawing(_ rectangle: GridRectangle? = nil) {
    if let rectangle {
      self.setNeedsDisplay(
        self.cellsGeometry.upsideDownRect(
          from: self.cellsGeometry.cellsRect(
            for: rectangle
          ),
          parentViewHeight: self.bounds.height
        )
      )

    } else {
      self.setNeedsDisplay(self.bounds)
    }
  }

  func flushIfNeeded() {
    DispatchQueues.GridViewSynchronization.dispatchQueue.async(flags: .barrier) {
      self.needsSynchronization = true
    }
  }

  private var needsSynchronization = false
  private var lastCursorPosition: GridPoint?

  private var windowState: State.Window {
    self.state.windows[self.gridID]!
  }

  private var grid: Grid<Cell?> {
    self.windowState.grid
  }

  private var cellsGeometry: CellsGeometry {
    .shared
  }
}
