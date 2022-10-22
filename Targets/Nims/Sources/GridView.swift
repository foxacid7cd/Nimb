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
  init(frame: NSRect, gridID: Int) {
    self.gridID = gridID
    super.init(frame: frame)

    self <~ self.stateChanges
      .extract { (/StateChange.grid).extract(from: $0) }
      .filter { $0.id == gridID }
      .bind(with: self) { $0.handle(stateChange: $1.change) }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func draw(_: NSRect) {
    let context = NSGraphicsContext.current!.cgContext

    context.saveGState()
    defer { context.restoreGState() }

    for rect in self.rectsBeingDrawn() {
      let gridRectangle = self.cellsGeometry.gridRectangle(cellsRect: rect)
        .intersection(.init(origin: .init(), size: self.grid.size))

      for columnOffset in 0 ..< gridRectangle.size.columnsCount {
        for rowOffset in 0 ..< gridRectangle.size.rowsCount {
          let index = GridPoint(
            row: gridRectangle.origin.row + rowOffset,
            column: gridRectangle.origin.column + columnOffset
          )

          let cellRect = self.cellsGeometry.cellRect(for: index)
          let text = self.grid[index]?.text ?? " "

          let glyphRuns: [CTRun] = {
            /* if let cachedGlyphRuns = self.cachedGlyphRuns(forKey: character) {
               return cachedGlyphRuns
             } */

            let attributedString = NSAttributedString(
              string: text,
              attributes: [.font: self.store.stateDerivatives.font.nsFont]
            )
            let typesetter = CTTypesetterCreateWithAttributedString(attributedString)
            let line = CTTypesetterCreateLine(typesetter, .init(location: 0, length: 1))

            let glyphRuns = CTLineGetGlyphRuns(line) as! [CTRun]
            // self.cache(glyphRuns: glyphRuns, forKey: character)
            return glyphRuns
          }()

          for glyphRun in glyphRuns {
            let glyphCount = CTRunGetGlyphCount(glyphRun)
            let range = CFRange(location: 0, length: glyphCount)
            let glyphs = [CGGlyph](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
              CTRunGetGlyphs(glyphRun, range, buffer.baseAddress!)
              initializedCount = glyphCount
            }
            let positions = [CGPoint](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
              CTRunGetPositions(glyphRun, range, buffer.baseAddress!)
              initializedCount = glyphCount
            }
            .map { CGPoint(x: $0.x + cellRect.origin.x, y: $0.y + cellRect.origin.y) }
            // context.cgContext.textMatrix = CTRunGetTextMatrix(glyphRun)
            /* context.cgContext.textPosition = self.cellOrigin(row: row, column: column)
             context.cgContext.showGlyphs(glyphs, at: positions) */

            context.saveGState()
            context.textMatrix = .identity
            // .scaledBy(x: 1, y: -1)
            // .translatedBy(x: cellRect.origin.x, y: cellRect.origin.y)
            context.setFillColor(.white)
            context.setTextDrawingMode(.fill)
            CTFontDrawGlyphs(self.store.stateDerivatives.font.nsFont, glyphs, positions, glyphCount, context)
            context.restoreGState()
            // CTFontDrawGlyphs(cgFont, glyphs, positions, glyphCount, context.cgContext)
          }
        }
      }
    }
  }

  private let gridID: Int

  // private var cachedGlyphs = [UInt16: CGGlyph]()
  // private let font = NSFont(name: "BlexMonoNerdFontCompleteM-", size: 13)!
  // private lazy var cgFont = CTFontCopyGraphicsFont(font, nil)

  // private lazy var queue = DispatchQueue(label: "foxacid7cd.Nims.glyphRunsCache.\(ObjectIdentifier(self))", qos: .userInteractive, attributes: .concurrent)
  // private var cachedGlyphRuns = [Character: [CTRun]]()

  @MainActor
  private var grid: CellGrid {
    self.state.grids[self.gridID]!
  }

  private var cellsGeometry: CellsGeometry {
    .shared
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
      self.setNeedsDisplay(
        cellsRect.insetBy(
          dx: -self.cellsGeometry.cellSize.width / 2,
          dy: -self.cellsGeometry.cellSize.height / 4
        )
      )

    case .clear, .size:
      self.setNeedsDisplay(self.bounds)

    default:
      break
    }
  }
}

private struct GlyphRun {
  var glyphs: [CGGlyph]
  var positions: [CGPoint]
}
