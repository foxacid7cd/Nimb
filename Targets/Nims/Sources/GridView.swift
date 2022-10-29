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

private let SerialDrawing = true

class GridView: NSView, EventListener {
  init(
    frame: NSRect,
    gridID: Int,
    glyphRunsCache: Cache<Character, [GlyphRun]>
  ) {
    self.gridID = gridID
    self.glyphRunsCache = glyphRunsCache
    super.init(frame: frame)

    self.listen()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func draw(_: NSRect) {
    let context = NSGraphicsContext.current!.cgContext

    context.saveGState()
    defer { context.restoreGState() }

    if self.synchronizeDrawingContext {
      context.synchronize()

      DispatchQueues.SerialDrawing.async(flags: .barrier) {
        self.synchronizeDrawingContext = false
      }
    }

    let font = self.store.stateDerivatives.font.nsFont
    let grid = self.grid

    let cursorPosition: GridPoint?
    if let cursor = self.state.cursor, cursor.gridID == self.gridID {
      cursorPosition = cursor.position

    } else {
      cursorPosition = nil
    }

    for rect in self.rectsBeingDrawn() {
      let gridRectangle = self.cellsGeometry.gridRectangle(
        cellsRect: self.cellsGeometry.upsideDownRect(
          from: rect,
          parentViewHeight: self.bounds.height
        )
      )
      .intersection(.init(origin: .init(), size: grid.size))

      for row in gridRectangle.rowsRange {
        for column in gridRectangle.columnsRange {
          let index = GridPoint(row: row, column: column)
          let character = grid[index]?.character ?? " "

          let glyphRuns: [GlyphRun] = {
            if let cachedGlyphRuns = self.glyphRunsCache[character] {
              return cachedGlyphRuns
            }

            let attributedString = NSAttributedString(
              string: String(character),
              attributes: [
                .font: font,
                .ligature: 0
              ]
            )
            let typesetter = CTTypesetterCreateWithAttributedString(attributedString)
            let line = CTTypesetterCreateLine(typesetter, .init(location: 0, length: 1))

            let ctRuns = CTLineGetGlyphRuns(line) as! [CTRun]
            let glyphRuns = ctRuns.map { ctRun in
              let glyphCount = CTRunGetGlyphCount(ctRun)
              let range = CFRange(location: 0, length: glyphCount)
              let glyphs = [CGGlyph](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
                CTRunGetGlyphs(ctRun, range, buffer.baseAddress!)
                initializedCount = glyphCount
              }
              let positions = [CGPoint](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
                CTRunGetPositions(ctRun, range, buffer.baseAddress!)
                initializedCount = glyphCount
              }
              return GlyphRun(glyphs: glyphs, positions: positions)
            }

            self.glyphRunsCache[character] = glyphRuns
            return glyphRuns
          }()

          let cellRect = self.cellsGeometry.upsideDownRect(
            from: self.cellsGeometry.cellRect(for: index),
            parentViewHeight: self.bounds.height
          )

          let isCursorCell = cursorPosition == index
          context.setFillColor(isCursorCell ? .white : .clear)
          context.fill([cellRect])

          for glyphRun in glyphRuns {
            context.saveGState()

            context.textMatrix = .identity
            context.setFillColor(isCursorCell ? .black : .white)
            context.setTextDrawingMode(.fill)

            CTFontDrawGlyphs(
              font,
              glyphRun.glyphs,
              glyphRun.offsetPositions(
                dx: cellRect.origin.x,
                dy: cellRect.origin.y - font.descender
              ),
              glyphRun.glyphs.count,
              context
            )

            context.restoreGState()
          }
        }
      }
    }
  }

  func published(event: Event) {
    switch event {
    case let .windowGridRowChanged(gridID, origin, columnsCount):
      guard gridID == self.gridID else {
        break
      }

      self.enqueueNeedsDisplay(
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
      guard gridID == self.gridID else {
        break
      }

      self.enqueueNeedsDisplay(
        self.cellsGeometry.insetForDrawing(
          rect: self.cellsGeometry.upsideDownRect(
            from: self.cellsGeometry.cellsRect(for: rectangle),
            parentViewHeight: self.bounds.height
          )
        )
      )

    case let .windowGridCleared(gridID):
      guard gridID == self.gridID else {
        break
      }

      self.enqueueNeedsDisplay(self.bounds)

    case let .cursorMoved(previousCursor):
      if let previousCursor, previousCursor.gridID == self.gridID {
        self.enqueueNeedsDisplay(
          self.cellsGeometry.insetForDrawing(
            rect: self.cellsGeometry.upsideDownRect(
              from: self.cellsGeometry.cellRect(
                for: previousCursor.position
              ),
              parentViewHeight: self.bounds.height
            )
          )
        )
      }

      if let cursor = self.state.cursor, cursor.gridID == self.gridID {
        self.enqueueNeedsDisplay(
          self.cellsGeometry.insetForDrawing(
            rect: self.cellsGeometry.upsideDownRect(
              from: self.cellsGeometry.cellRect(
                for: cursor.position
              ),
              parentViewHeight: self.bounds.height
            )
          )
        )
      }

    case .flushRequested:
      if SerialDrawing {
        for rect in self.needsDisplayBuffer {
          self.setNeedsDisplay(rect)
        }

        self.needsDisplayBuffer.removeAll(keepingCapacity: true)
      }

      DispatchQueues.SerialDrawing.async(flags: .barrier) {
        self.synchronizeDrawingContext = true
      }

    default:
      break
    }
  }

  private let gridID: Int
  private let glyphRunsCache: Cache<Character, [GlyphRun]>
  private var needsDisplayBuffer = [CGRect]()
  private var synchronizeDrawingContext = false

  private var windowState: State.Window {
    self.state.windows[self.gridID]!
  }

  private var grid: Grid<Cell?> {
    self.windowState.grid
  }

  private var cellsGeometry: CellsGeometry {
    .shared
  }

  private func enqueueNeedsDisplay(_ rect: CGRect) {
    if SerialDrawing {
      self.needsDisplayBuffer.append(rect)

    } else {
      self.setNeedsDisplay(rect)
    }
  }
}
