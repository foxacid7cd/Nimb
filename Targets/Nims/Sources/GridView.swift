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

  /* private var cachedGlyphs = [UInt16: CGGlyph]()
   private let font = NSFont(name: "BlexMonoNerdFontCompleteM-", size: 13)!
   private lazy var cgFont = CTFontCopyGraphicsFont(font, nil)

   private lazy var queue = DispatchQueue(label: "foxacid7cd.Nims.glyphRunsCache.\(ObjectIdentifier(self))", qos: .userInteractive, attributes: .concurrent)
   private var cachedGlyphRuns = [Character: [CTRun]]()

   @MainActor
   private var grid: CellGrid {
     self.state.grids[self.gridID]!
   }

   private var cellSize: CGSize {
     self.store.stateDerivatives.fontCalculation.cellSize
   }

   private func cache(glyphRuns: [CTRun], forKey key: Character) {
     self.queue.async(flags: .barrier) {
       self.cachedGlyphRuns[key] = glyphRuns
     }
   }

   private func cachedGlyphRuns(forKey key: Character) -> [CTRun]? {
     self.queue.sync {
       cachedGlyphRuns[key]
     }
   }

   private func gridIntersection(with rect: CGRect) -> (row: Int, column: Int, width: Int, height: Int) {
     let grid = self.grid
     let gridFrame = self.gridFrame

     let intersection = gridFrame.intersection(rect)

     let row = Int(floor(intersection.minY / Store.state.cellSize.height))
     let column = Int(floor(intersection.minX / Store.state.cellSize.width))

     let width = min(
       grid.columnsCount,
       Int(ceil(intersection.maxX / Store.state.cellSize.width))
     ) - column

     let height = min(
       grid.rowsCount,
       Int(ceil(intersection.maxY / Store.state.cellSize.height))
     ) - row

     return (row, column, width, height)
   }

   private func cellsRect(first: (row: Int, column: Int), second: (row: Int, column: Int)) -> CGRect {
     let firstRect = self.cellRect(row: first.row, column: first.column)
     let secondRect = self.cellRect(row: second.row, column: second.column)
     return firstRect.union(secondRect)
   }

   private func cellRect(at index: GridPoint) -> CGRect {
     .init(
       origin: self.cellOrigin(at index),
       size: Store.state.cellSize
     )
   }

   private func cellOrigin(at index: GridPoint) -> CGPoint {
     .init(
       x: Double(index.column) * Store.state.cellSize.width,
       y: Double(index.row) * Store.state.cellSize.height
     )
   } */
//  override public func draw(_: NSRect) {
//    let context = NSGraphicsContext.current!.cgContext
//
//    context.saveGState()
//    defer { context.restoreGState() }

//    context.cgContext.setFillColor(NSColor.green.cgColor)
//    context.cgContext.fill([rect])
//    log(.debug, rect)
//    return

//    let grid = self.grid
//    let gridFrame = self.gridFrame
//
//    for rect in self.rectsBeingDrawn() {
//      let intersection = rect.intersection(gridFrame)
//      let gridIntersection = self.gridIntersection(with: intersection)
//
//      for columnOffset in 0 ..< gridIntersection.width {
//        for rowOffset in 0 ..< gridIntersection.height {
//          let row = gridIntersection.row + rowOffset
//          let column = gridIntersection.column + columnOffset
//
//          let cellRect = self.cellRect(row: row, column: column)
//          let character = grid[row, column]?.character ?? " "
//
//          let glyphRuns: [CTRun] = {
//            if let cachedGlyphRuns = self.cachedGlyphRuns(forKey: character) {
//              return cachedGlyphRuns
//            }
//
//            let attributedString = NSAttributedString(
//              string: String(character),
//              attributes: [.font: self.font]
//            )
//            let typesetter = CTTypesetterCreateWithAttributedString(attributedString)
//            let line = CTTypesetterCreateLine(typesetter, .init(location: 0, length: 1))
//
//            let glyphRuns = CTLineGetGlyphRuns(line) as! [CTRun]
//            self.cache(glyphRuns: glyphRuns, forKey: character)
//            return glyphRuns
//          }()
//
//          for glyphRun in glyphRuns {
//            let glyphCount = CTRunGetGlyphCount(glyphRun)
//            let range = CFRange(location: 0, length: glyphCount)
//            let glyphs = [CGGlyph](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
//              CTRunGetGlyphs(glyphRun, range, buffer.baseAddress!)
//              initializedCount = glyphCount
//            }
//            let positions = [CGPoint](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
//              CTRunGetPositions(glyphRun, range, buffer.baseAddress!)
//              initializedCount = glyphCount
//            }
//            .map { CGPoint(x: $0.x + cellRect.origin.x, y: $0.y + cellRect.origin.y) }
//            // context.cgContext.textMatrix = CTRunGetTextMatrix(glyphRun)
//            /* context.cgContext.textPosition = self.cellOrigin(row: row, column: column)
//             context.cgContext.showGlyphs(glyphs, at: positions) */
//
//            context.saveGState()
//            context.textMatrix = .identity
//            // .scaledBy(x: 1, y: -1)
//            // .translatedBy(x: cellRect.origin.x, y: cellRect.origin.y)
//            context.setFillColor(.white)
//            context.setTextDrawingMode(.fill)
//            CTFontDrawGlyphs(self.font, glyphs, positions, glyphCount, context)
//            context.restoreGState()
//            // CTFontDrawGlyphs(cgFont, glyphs, positions, glyphCount, context.cgContext)
//          }
//        }
//      }
//    }
//  }

  private let gridID: Int

  private var cellsGeometry: CellsGeometry {
    .shared
  }

  private var grid: CellGrid {
    self.store.state.grids[self.gridID]!
  }

  private func handle(stateChange: StateChange.Grid.Change) {
    switch stateChange {
    case let .row(rowChange):
      let rect = self.cellsGeometry.cellsRect(
        for: .init(
          origin: rowChange.origin,
          size: .init(
            rowsCount: 1,
            columnsCount: rowChange.columnsCount
          )
        )
      )
      self.setNeedsDisplay(rect)

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
