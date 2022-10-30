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
      self.highlightChanged = true

    case .flushRequested:
      if self.highlightChanged {
        self.backgroundView.setNeedsDisplay(self.bounds)
        self.foregroundView.setNeedsDisplay(self.bounds)
        self.highlightChanged = false
        self.needsDisplayBuffer.removeAll(keepingCapacity: true)

      } else {
        if SerialDrawing {
          for rect in self.needsDisplayBuffer {
            self.backgroundView.setNeedsDisplay(rect)
            self.foregroundView.setNeedsDisplay(
              self.cellsGeometry.insetForDrawing(rect: rect)
            )
          }

          self.needsDisplayBuffer.removeAll(keepingCapacity: true)
        }

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
      self.foregroundView.setNeedsDisplay(
        self.cellsGeometry.insetForDrawing(rect: rect)
      )
    }
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
        let characters = gridRectangle.columnsRange
          .compactMap { column -> Character? in
            guard let cell = self.grid[.init(row: row, column: column)] else {
              return " "
            }

            return cell.character
          }
        let text = String(characters)

        let origin = GridPoint(row: row, column: gridRectangle.origin.column)
        let cellsRect = self.cellsGeometry.upsideDownRect(
          from: self.cellsGeometry.cellsRect(
            for: .init(
              origin: origin,
              size: .init(
                rowsCount: 1,
                columnsCount: gridRectangle.size.columnsCount
              )
            )
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
          let line = CTTypesetterCreateLine(typesetter, .init(location: 0, length: text.count))

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
          context.setFillColor(.white)

          CTFontDrawGlyphs(
            font,
            glyphRun.glyphs,
            glyphRun.offsetPositions(
              dx: cellsRect.origin.x,
              dy: cellsRect.origin.y - font.descender
            ),
            glyphRun.glyphs.count,
            context
          )

          context.restoreGState()
        }

        var latestHighlight: (rectangle: GridRectangle, id: Int?)?
        func drawHighlight() {
          guard let (rectangle, id) = latestHighlight else {
            return
          }

          let highlight = id.flatMap { self.state.highlights[$0] } ?? self.state.defaultHighlight
          if let color = highlight.reverse ? highlight.backgroundColor : highlight.foregroundColor {
            context.saveGState()

            context.setBlendMode(.sourceIn)
            context.setFillColor(self.cgColor(for: color))

            let rect = self.cellsGeometry.upsideDownRect(
              from: self.cellsGeometry.cellsRect(for: rectangle),
              parentViewHeight: self.bounds.height
            )
            context.fill([rect])

            context.restoreGState()
          }
        }

        for column in gridRectangle.columnsRange {
          let index = GridPoint(row: row, column: column)
          let cell = self.grid[index]

          let hlID: Int?
          if let cell, cell.character != " " {
            hlID = cell.hlID
          } else {
            hlID = nil
          }

          if let (rectangle, id) = latestHighlight {
            if id == hlID {
              var newRectangle = rectangle
              newRectangle.size.columnsCount += 1
              latestHighlight = (newRectangle, id)
              continue

            } else {
              drawHighlight()
            }
          }

          let rectangle = GridRectangle(
            origin: .init(row: row, column: column),
            size: .init(rowsCount: 1, columnsCount: 1)
          )
          latestHighlight = (rectangle, hlID)
        }

        drawHighlight()

        if let cursorPosition, cursorPosition.row == row, gridRectangle.columnsRange.contains(cursorPosition.column), let color = self.state.defaultHighlight.backgroundColor {
          context.saveGState()
          context.setFillColor(self.cgColor(for: color))
          context.setBlendMode(.sourceIn)

          let rect = self.cellsGeometry.upsideDownRect(
            from: self.cellsGeometry.cellRect(
              for: cursorPosition
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

  private let gridID: Int
  private let glyphRunsCache: Cache<String, [GlyphRun]>
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
        var latestHighlight: (rectangle: GridRectangle, id: Int?)?
        func drawHighlight() {
          guard let (rectangle, id) = latestHighlight else {
            return
          }

          context.saveGState()

          let highlight = id.flatMap { self.state.highlights[$0] } ?? self.state.defaultHighlight
          if let color = highlight.reverse ? highlight.foregroundColor : highlight.backgroundColor {
            context.setFillColor(self.cgColor(for: color))
          } else {
            context.setFillColor(.clear)
          }

          let rect = self.cellsGeometry.upsideDownRect(
            from: self.cellsGeometry.cellsRect(for: rectangle),
            parentViewHeight: self.bounds.height
          )
          context.fill([rect])

          context.restoreGState()
        }

        for column in gridRectangle.columnsRange {
          let index = GridPoint(row: row, column: column)
          let cell = self.grid[index]
          let hlID = cell?.hlID

          if let (rectangle, id) = latestHighlight {
            if id == hlID {
              var newRectangle = rectangle
              newRectangle.size.columnsCount += 1
              latestHighlight = (newRectangle, id)
              continue

            } else {
              drawHighlight()
            }
          }

          let rectangle = GridRectangle(
            origin: .init(row: row, column: column),
            size: .init(rowsCount: 1, columnsCount: 1)
          )
          latestHighlight = (rectangle, hlID)
        }

        drawHighlight()

        if let cursorPosition, cursorPosition.row == row, gridRectangle.columnsRange.contains(cursorPosition.column), let color = self.state.defaultHighlight.foregroundColor {
          context.saveGState()

          context.setFillColor(self.cgColor(for: color))

          let rect = self.cellsGeometry.upsideDownRect(
            from: self.cellsGeometry.cellRect(
              for: cursorPosition
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
