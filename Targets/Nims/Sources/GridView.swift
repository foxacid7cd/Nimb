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

class GridView: NSView, EventListener, CALayerDelegate {
  init(
    frame: NSRect,
    gridID: Int,
    glyphRunsCache: Cache<String, [GlyphRun]>
  ) {
    self.gridID = gridID

    let subviewFrame = NSRect(origin: .init(), size: frame.size)
    self.backgroundView = .init(frame: subviewFrame, gridID: gridID)
    self.foregroundView = .init(frame: subviewFrame, gridID: gridID, glyphRunsCache: glyphRunsCache)

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
      guard gridID == self.gridID else {
        break
      }

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
      guard gridID == self.gridID else {
        break
      }

      self.enqueueNeedsDisplay(
        self.cellsGeometry.upsideDownRect(
          from: self.cellsGeometry.cellsRect(for: rectangle),
          parentViewHeight: self.bounds.height
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
      self.foregroundView.setNeedsDisplay(self.bounds)
      self.backgroundView.setNeedsDisplay(self.bounds)

    case .flushRequested:
      if SerialDrawing {
        for rect in self.needsDisplayBuffer {
          self.backgroundView.setNeedsDisplay(rect)
          self.foregroundView.setNeedsDisplay(self.cellsGeometry.insetForDrawing(rect: rect))
        }

        self.needsDisplayBuffer.removeAll(keepingCapacity: true)
      }

      DispatchQueues.SerialDrawing.async(flags: .barrier) {
        self.backgroundView.synchronizeDrawingContext = true
        self.foregroundView.synchronizeDrawingContext = true
      }

    default:
      break
    }
  }

  private let backgroundView: BackgroundView
  private let foregroundView: ForegroundView
  private var needsDisplayBuffer = [CGRect]()

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
      self.backgroundView.setNeedsDisplay(rect)
      self.foregroundView.setNeedsDisplay(self.cellsGeometry.insetForDrawing(rect: rect))
    }
  }
}

private class ForegroundView: NSView {
  init(
    frame: NSRect,
    gridID: Int,
    glyphRunsCache: Cache<String, [GlyphRun]>
  ) {
    self.gridID = gridID
    self.glyphRunsCache = glyphRunsCache
    super.init(frame: frame)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func draw(_: NSRect) {
    let context = NSGraphicsContext.current!.cgContext

    context.saveGState()
    defer { context.restoreGState() }

    context.setShouldAntialias(true)
    context.setShouldSmoothFonts(true)
    context.setShouldSubpixelPositionFonts(true)
    context.setShouldSubpixelQuantizeFonts(true)

    let font = self.store.stateDerivatives.font.nsFont

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
      .intersection(.init(size: self.windowState.frame.size))

      guard let gridRectangle else {
        continue
      }

      for row in gridRectangle.rowsRange {
        for column in gridRectangle.columnsRange {
          let index = GridPoint(row: row, column: column)
          let cell = self.grid[index]
          let highlight = cell.flatMap { self.state.highlights[$0.hlID]?.normalized } ?? self.state.defaultHighlight
          let text = String(cell?.character ?? " ")

          let cellRect = self.cellsGeometry.upsideDownRect(
            from: self.cellsGeometry.cellRect(
              for: index
            ),
            parentViewHeight: self.bounds.height
          )

          let glyphRuns: [GlyphRun] = {
            if let cachedGlyphRuns = self.glyphRunsCache[text] {
              return cachedGlyphRuns
            }

            let attributedString = NSAttributedString(
              string: text,
              attributes: [.font: font]
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
              return GlyphRun(
                glyphs: glyphs,
                positions: positions
              )
            }

            self.glyphRunsCache[text] = glyphRuns
            return glyphRuns
          }()

          for glyphRun in glyphRuns {
            context.saveGState()

            context.textMatrix = .identity
            context.setTextDrawingMode(.fill)
            context.setFillColor(highlight.foregroundColor?.cgColor ?? .clear)

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

          if let cursorPosition, cursorPosition.row == row, gridRectangle.columnsRange.contains(cursorPosition.column) {
            let cursorRect = self.cellsGeometry.upsideDownRect(
              from: self.cellsGeometry.cellRect(
                for: cursorPosition
              ),
              parentViewHeight: self.bounds.height
            )

            context.saveGState()

            context.setBlendMode(.sourceIn)
            context.setFillColor(self.state.defaultHighlight.backgroundColor?.cgColor ?? .clear)
            context.fill([cursorRect])

            context.restoreGState()
          }
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

  private let gridID: Int
  private let glyphRunsCache: Cache<String, [GlyphRun]>

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

private class BackgroundView: NSView {
  init(
    frame: NSRect,
    gridID: Int
  ) {
    self.gridID = gridID
    super.init(frame: frame)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func draw(_: NSRect) {
    let context = NSGraphicsContext.current!.cgContext

    context.saveGState()
    defer { context.restoreGState() }

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
      .intersection(.init(size: grid.size))

      guard let gridRectangle else {
        continue
      }

      for row in gridRectangle.rowsRange {
        for column in gridRectangle.columnsRange {
          let index = GridPoint(row: row, column: column)
          let highlight = self.grid[index].flatMap { self.state.highlights[$0.hlID]?.normalized } ?? self.state.defaultHighlight
          let cellRect = self.cellsGeometry.upsideDownRect(
            from: self.cellsGeometry.cellRect(
              for: index
            ),
            parentViewHeight: self.bounds.height
          )

          context.saveGState()

          context.setFillColor(highlight.backgroundColor?.cgColor ?? .clear)
          context.fill([cellRect])

          context.restoreGState()

          if let cursorPosition, cursorPosition.row == row, gridRectangle.columnsRange.contains(cursorPosition.column) {
            let cursorRect = self.cellsGeometry.upsideDownRect(
              from: self.cellsGeometry.cellRect(
                for: cursorPosition
              ),
              parentViewHeight: self.bounds.height
            )

            context.saveGState()

            context.setFillColor(self.state.defaultHighlight.foregroundColor?.cgColor ?? .clear)
            context.fill([cursorRect])

            context.restoreGState()
          }
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

  private let gridID: Int

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
