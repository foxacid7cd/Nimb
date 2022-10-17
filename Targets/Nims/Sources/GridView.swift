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

  @MainActor
  override public func draw(_: NSRect) {
    let context = NSGraphicsContext.current!

    context.cgContext.saveGState()
    defer { context.cgContext.restoreGState() }

    var rects: UnsafePointer<NSRect>!
    var count = 0
    getRectsBeingDrawn(&rects, count: &count)

    let grid = self.grid
    let gridSize = Store.shared.state.gridSize(id: self.id)

    for index in 0 ..< count {
      let rect = rects.advanced(by: index).pointee
        .intersection(.init(origin: .zero, size: gridSize))

      let gridIntersection = self.gridIntersection(with: rect)

      var glyphs = [CGGlyph]()
      var positions = [CGPoint]()

      for columnOffset in 0 ..< gridIntersection.width {
        for rowOffset in 0 ..< gridIntersection.height {
          let row = gridIntersection.row + rowOffset
          let column = gridIntersection.column + columnOffset

          if
            let cell = grid[.init(row: row, column: column)],
            let rawCharacter = cell.character?.utf16.first {
            let glyph: CGGlyph
            if let cachedGlyph = self.cachedGlyphs[rawCharacter] {
              glyph = cachedGlyph

            } else {
              var glyphs = [CGGlyph(0)]
              CTFontGetGlyphsForCharacters(self.font, [rawCharacter], &glyphs, 1)
              glyph = glyphs[0]
            }

            let position = self.cellOrigin(row: row, column: column)

            glyphs.append(glyph)
            positions.append(position)
          }
        }
      }

      context.cgContext.textMatrix = .identity
      // context.cgContext.translateBy(x: 0, y: gridSize.height)
      // context.cgContext.scaleBy(x: 1, y: -1)

      log(.debug, "drawing \(glyphs.count) glyphs")

      CTFontDrawGlyphs(
        self.font,
        glyphs,
        positions,
        glyphs.count,
        context.cgContext
      )
    }
  }

  private let id: Int
  private var cancellables = Set<AnyCancellable>()
  private var cachedGlyphs = [UInt16: CGGlyph]()
  private let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

  private var grid: Grid<State.Cell?> {
    Store.shared.state.grids[self.id]!
  }

  private var gridFrame: CGRect {
    .init(origin: .zero, size: Store.shared.state.gridSize(id: self.id))
  }

  private var cellSize: CGSize {
    Store.shared.state.cellSize
  }

  private func handle(notifications: [Store.Notification]) {
    for notification in notifications {
      switch notification {
      case let .gridUpdated(id, updates):
        guard id == self.id else {
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

    let row = Int(floor(intersection.minY / self.cellSize.height))
    let column = Int(floor(intersection.minX / self.cellSize.width))

    let width = min(
      grid.columnsCount,
      Int(ceil(intersection.maxX / self.cellSize.width))
    ) - column

    let height = min(
      grid.rowsCount,
      Int(ceil(intersection.maxY / self.cellSize.height))
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
      size: Store.shared.state.cellSize
    )
  }

  private func cellOrigin(row: Int, column: Int) -> CGPoint {
    .init(
      x: Double(column) * Store.shared.state.cellSize.width,
      y: Double(row) * Store.shared.state.cellSize.height
    )
  }
}
