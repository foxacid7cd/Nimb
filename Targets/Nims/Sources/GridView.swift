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

    Store.shared.notifications
      .sink { [weak self] in self?.handle(notifications: $0) }
      .store(in: &self.cancellables)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func draw(_: NSRect) {
    let context = NSGraphicsContext.current!

    context.saveGraphicsState()
    defer { context.restoreGraphicsState() }

    var rects: UnsafePointer<NSRect>!
    var count = 0
    self.getRectsBeingDrawn(&rects, count: &count)

    let grid = self.grid
    let gridSize = Store.state.gridSize(id: self.id)

    for index in 0 ..< count {
      let rect = rects.advanced(by: index).pointee
        .intersection(.init(origin: .zero, size: gridSize))

      let gridIntersection = self.gridIntersection(with: rect)

      for columnOffset in 0 ..< gridIntersection.width {
        for rowOffset in 0 ..< gridIntersection.height {
          let row = gridIntersection.row + rowOffset
          let column = gridIntersection.column + columnOffset
          let cellRect = self.cellRect(row: row, column: column)

          if let cell = grid[row, column] {
            let string = cell.character.map { String($0) } ?? " "
            let attributedString = NSAttributedString(string: string, attributes: [.font: self.font, .foregroundColor: NSColor.green])
            let line = CTLineCreateWithAttributedString(attributedString)
            let glyphRuns = CTLineGetGlyphRuns(line) as! [CTRun]
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
              // context.cgContext.textMatrix = CTRunGetTextMatrix(glyphRun)
              /* context.cgContext.textPosition = self.cellOrigin(row: row, column: column)
               context.cgContext.showGlyphs(glyphs, at: positions) */

              context.cgContext.setFillColor(.black)
              context.cgContext.fill(cellRect)

              print(glyphs, positions)
              context.cgContext.textMatrix = .identity
                // .scaledBy(x: 1, y: -1)
                .translatedBy(x: cellRect.origin.x, y: cellRect.origin.y)
              context.cgContext.setFillColor(.white)
              context.cgContext.setAlpha(1)
              context.cgContext.setFont(self.cgFont)
              context.cgContext.setFontSize(13)
              context.cgContext.setTextDrawingMode(.fill)
              context.cgContext.showGlyphs(glyphs, at: positions)
              // CTFontDrawGlyphs(cgFont, glyphs, positions, glyphCount, context.cgContext)
            }
          }
        }
      }
    }

    context.cgContext.flush()
  }

  private let id: Int
  private var cancellables = Set<AnyCancellable>()
  private var cachedGlyphs = [UInt16: CGGlyph]()
  private let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
  private lazy var cgFont = CTFontCopyGraphicsFont(font, nil)

  private var grid: Grid<State.Cell?> {
    Store.state.grids[self.id]!
  }

  private var gridFrame: CGRect {
    .init(origin: .zero, size: Store.state.gridSize(id: self.id))
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
