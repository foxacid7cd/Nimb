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
import RxCocoa
import RxSwift

class GridView: NSView {
  init(
    frame: NSRect,
    gridID: Int,
    cellsGeometry: CellsGeometry,
    glyphRunsCache: Cache<Character, [GlyphRun]>
  ) {
    self.gridID = gridID
    self.cellsGeometry = cellsGeometry
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
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func draw(_: NSRect) {
    let context = NSGraphicsContext.current!.cgContext

    context.saveGState()
    defer { context.restoreGState() }

    let font = self.store.stateDerivatives.font.nsFont

    let cursorIndex: GridPoint?
    if let cursor = self.state.cursor, cursor.gridID == self.gridID {
      cursorIndex = cursor.index

    } else {
      cursorIndex = nil
    }

    for rect in self.rectsBeingDrawn() {
      let gridRectangle = self.cellsGeometry.gridRectangle(cellsRect: rect)

      for columnOffset in 0 ..< gridRectangle.size.columnsCount {
        for rowOffset in 0 ..< gridRectangle.size.rowsCount {
          let index = GridPoint(
            row: gridRectangle.origin.row + rowOffset,
            column: gridRectangle.origin.column + columnOffset
          )

          let character = self.grid[index]?.character ?? " "

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
  private let cellsGeometry: CellsGeometry
  private let glyphRunsCache: Cache<Character, [GlyphRun]>

  @MainActor
  private var grid: CellGrid {
    self.state.grids[self.gridID]!.grid
  }

  private func handle(stateChange: StateChange.Grid.Change) {
    switch stateChange {
    case let .row(rowChange):
      let cellsRect = self.cellsGeometry.cellsRect(
        for: .init(
          origin: .init(
            row: rowChange.origin.row,
            column: rowChange.origin.column
          ),
          size: .init(
            rowsCount: 1,
            columnsCount: rowChange.columnsCount
          )
        )
      )

      self.setNeedsDisplay(
        self.cellsGeometry.insetForDrawing(rect: cellsRect)
      )

    case let .rectangle(rectangle):
      let cellsRect = self.cellsGeometry.cellsRect(for: rectangle)
      self.setNeedsDisplay(cellsRect)

    case .clear, .size:
      self.setNeedsDisplay(self.bounds)

    default:
      break
    }
  }

  private func handle(cursorIndex: GridPoint) {
    self.setNeedsDisplay(self.cellsGeometry.cellRect(for: cursorIndex))
  }
}
