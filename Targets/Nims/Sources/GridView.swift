//
//  GridView.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Combine
import Library

class GridView: NSView {
  init(id: Int) {
    self.id = id
    super.init(frame: .init())

    self.wantsLayer = true
    self.layer?.backgroundColor = .black

    Store.shared.notifications
      .subscribe(onNext: { [weak self] in self?.handle(notifications: $0) })
      .disposed(by: self.associatedDisposeBag)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func draw(_: NSRect) {
    let context = NSGraphicsContext.current!.cgContext

    context.saveGState()
    defer { context.restoreGState() }

//    context.cgContext.setFillColor(NSColor.green.cgColor)
//    context.cgContext.fill([rect])
//    log(.debug, rect)
//    return

    let grid = self.grid
    let gridFrame = self.gridFrame

    for rect in self.rectsBeingDrawn() {
      let intersection = rect.intersection(gridFrame)
      let gridIntersection = self.gridIntersection(with: intersection)

      for columnOffset in 0 ..< gridIntersection.width {
        for rowOffset in 0 ..< gridIntersection.height {
          let row = gridIntersection.row + rowOffset
          let column = gridIntersection.column + columnOffset

          let cellRect = self.cellRect(row: row, column: column)
          let character = grid[row, column]?.character ?? " "

          let glyphRuns: [CTRun] = {
            if let cachedGlyphRuns = self.cachedGlyphRuns(forKey: character) {
              return cachedGlyphRuns
            }

            let attributedString = NSAttributedString(
              string: String(character),
              attributes: [.font: self.font]
            )
            let typesetter = CTTypesetterCreateWithAttributedString(attributedString)
            let line = CTTypesetterCreateLine(typesetter, .init(location: 0, length: 1))

            let glyphRuns = CTLineGetGlyphRuns(line) as! [CTRun]
            self.cache(glyphRuns: glyphRuns, forKey: character)
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
            CTFontDrawGlyphs(self.font, glyphs, positions, glyphCount, context)
            context.restoreGState()
            // CTFontDrawGlyphs(cgFont, glyphs, positions, glyphCount, context.cgContext)
          }
        }
      }
    }
  }

  private let id: Int
  private var cachedGlyphs = [UInt16: CGGlyph]()
  private let font = NSFont(name: "BlexMonoNerdFontCompleteM-", size: 13)!
  private lazy var cgFont = CTFontCopyGraphicsFont(font, nil)

  private lazy var queue = DispatchQueue(label: "foxacid7cd.Nims.glyphRunsCache.\(ObjectIdentifier(self))", qos: .userInteractive, attributes: .concurrent)

  private var cachedGlyphRuns = [Character: [CTRun]]() {
    didSet {
      log(.debug, self.cachedGlyphRuns)
    }
  }

  private var grid: Grid<State.Cell?> {
    Store.state.grids[self.id]!
  }

  private var gridFrame: CGRect {
    .init(origin: .zero, size: Store.state.gridSize(id: self.id))
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

  private func handle(notifications: [Store.Notification]) {
    for notification in notifications {
      switch notification {
      case let .gridUpdated(id, updates):
        guard id == self.id
        else {
          continue
        }
        switch updates {
        case let .line(row, columnStart, cellsCount):
          let updatedRect = self.cellsRect(first: (row, columnStart), second: (row, columnStart + cellsCount))
          self.setNeedsDisplay(updatedRect)
          self.displayIfNeeded(updatedRect)
        }

      default:
        continue
      }
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

  private func cellRect(row: Int, column: Int) -> CGRect {
    .init(
      origin: self.cellOrigin(row: row, column: column),
      size: Store.state.cellSize
    )
  }

  private func cellOrigin(row: Int, column: Int) -> CGPoint {
    .init(
      x: Double(column) * Store.state.cellSize.width,
      y: Double(row) * Store.state.cellSize.height
    )
  }
}

private struct GlyphRun {
  var glyphs: [CGGlyph]
  var positions: [CGPoint]
}
