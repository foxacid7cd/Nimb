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

private let SerialDrawing = false

class GridView: NSView {
  init(
    frame: NSRect,
    gridID: Int,
    windowRef: ExtendedTypes.Window?,
    glyphRunsCache: Cache<Character, [GlyphRun]>
  ) {
    self.gridID = gridID
    self.windowRef = windowRef
    self.glyphRunsCache = glyphRunsCache
    super.init(frame: frame)

    self <~ self.stateChanges
      .extract { (/StateChange.grid).extract(from: $0) }
      .filter { $0.id == gridID }
      .bind(with: self) { $0.handle(stateChange: $1.change) }

    self <~ self.stateChanges
      .extract { (/StateChange.cursor).extract(from: $0) }
      .filter { $0.gridID == gridID }
      .bind(with: self) { $0.handle(cursorIndex: $1.index) }

    self <~ self.stateChanges
      .extract { (/StateChange.flush).extract(from: $0) }
      .bind(with: self) { view, _ in view.handleFlush() }
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
      log(.info, "GridView drawing context synchronized")

      self.barrierDispatchQueue.async(flags: .barrier) {
        self.synchronizeDrawingContext = false
      }
    }

    let font = self.store.stateDerivatives.font.nsFont

    let cursorIndex: GridPoint?
    if let cursor = self.state.cursor, cursor.gridID == self.gridID {
      cursorIndex = cursor.index

    } else {
      cursorIndex = nil
    }

    guard let cellGrid = self.grid?.cellGrid else {
      return
    }

    for rect in self.rectsBeingDrawn() {
      let gridRectangle = self.cellsGeometry.gridRectangle(cellsRect: rect)

      for columnOffset in 0 ..< gridRectangle.size.columnsCount {
        for rowOffset in 0 ..< gridRectangle.size.rowsCount {
          let index = GridPoint(
            row: max(0, min(cellGrid.size.rowsCount - 1, cellGrid.size.rowsCount - 1 - gridRectangle.origin.row - rowOffset)),
            column: max(0, min(cellGrid.size.columnsCount - 1, gridRectangle.origin.column + columnOffset))
          )

          let character = cellGrid[index]?.character ?? " "

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

          let cellRect = self.cellsGeometry.cellRect(for: index)
            .applying(self.upsideDownTransform)

          let isCursorCell = cursorIndex == index
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

  private let gridID: Int
  private let windowRef: ExtendedTypes.Window?
  private let glyphRunsCache: Cache<Character, [GlyphRun]>
  private var needsDisplayBuffer = [CGRect]()

  private let barrierDispatchQueue = DispatchQueue.global(qos: .default)
  private var synchronizeDrawingContext = false

  private var cellsGeometry: CellsGeometry {
    .shared
  }

  private var upsideDownTransform: CGAffineTransform {
    .identity
      .scaledBy(x: 1, y: -1)
      .translatedBy(x: 0, y: -self.bounds.size.height)
  }

  @MainActor
  private var grid: State.Grid? {
    self.state.grids[self.gridID]
  }

  @MainActor
  private var gridWindow: State.Grid.Window? {
    .init(
      size: .init(),
      frame: .init(
        origin: .init(row: 0, column: 0),
        size: self.grid?.cellGrid.size ?? .init()
      ),
      isHidden: false
    )
  }

  private func handle(stateChange: StateChange.Grid.Change) {
    switch stateChange {
    case let .row(rowChange):
      let cellsRect = self.cellsGeometry.cellsRect(
        for: .init(
          origin: rowChange.origin,
          size: .init(
            rowsCount: 1,
            columnsCount: rowChange.columnsCount
          )
        )
      )
      let rect = self.cellsGeometry.insetForDrawing(rect: cellsRect)
      self.enqueueNeedsDisplay(rect: rect.applying(self.upsideDownTransform))

    case let .rectangle(rectangle):
      let rect = self.cellsGeometry.insetForDrawing(
        rect: self.cellsGeometry.cellsRect(for: rectangle)
      )
      self.enqueueNeedsDisplay(rect: rect.applying(self.upsideDownTransform))

    case .clear, .size:
      self.enqueueNeedsDisplay(rect: self.bounds)

    default:
      break
    }
  }

  private func handle(cursorIndex: GridPoint) {
    let rect = self.cellsGeometry.insetForDrawing(
      rect: self.cellsGeometry.cellRect(
        for: cursorIndex
      )
    )
    .applying(self.upsideDownTransform)

    self.enqueueNeedsDisplay(rect: rect)
  }

  private func handleFlush() {
    if SerialDrawing {
      for rect in self.needsDisplayBuffer {
        self.setNeedsDisplay(rect)
      }

      self.needsDisplayBuffer.removeAll(keepingCapacity: true)
    }

    self.barrierDispatchQueue.async(flags: .barrier) {
      self.synchronizeDrawingContext = true
    }
  }

  private func enqueueNeedsDisplay(rect: CGRect) {
    if SerialDrawing {
      self.needsDisplayBuffer.append(rect)

    } else {
      self.setNeedsDisplay(rect)
    }
  }
}
