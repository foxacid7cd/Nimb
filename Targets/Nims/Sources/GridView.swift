//
//  GridView.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import API
import AppKit
import CasePaths
import Combine
import DequeModule
import Library
import RxCocoa
import RxSwift

class GridView: NSView {
  @MainActor
  init(
    frame: NSRect,
    state: State,
    gridID: Int
  ) {
    self.state = state
    self.gridID = gridID
    super.init(frame: frame)

    // self.canDrawConcurrently = true
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  enum DrawingRequest {
    case draw(GridRectangle)
    case copy(from: GridRectangle, originDelta: GridPoint)
  }

  enum DrawingOperation {
    case draw(CGRect, GridRectangle)
    case copy(from: CGPoint, to: CGPoint, size: CGSize, toRectangle: GridRectangle)

    var targetRect: CGRect {
      switch self {
      case let .draw(rect, _):
        return rect

      case let .copy(_, to, size, _):
        return .init(origin: to, size: size)
      }
    }
  }

  let gridID: Int

  @MainActor
  var state: State

  override var isOpaque: Bool {
    true
  }

  override func draw(_: NSRect) {
    let state = self.state
    let fontDerivatives = StateDerivatives.shared.font(state: state)
    let cellSize = fontDerivatives.cellSize

    guard let context = NSGraphicsContext.current, let window = state.windows[self.gridID] else {
      return
    }

    context.saveGraphicsState()
    defer { context.restoreGraphicsState() }

    let rects = self.rectsBeingDrawn()

    context.cgContext.setFillColor(state.defaultHighlight.backgroundColor?.cgColor ?? .clear)
    context.cgContext.fill(rects)

    let drawingOperations = self.currentDrawingOperations
      .filter { operation in
        rects.contains { $0.contains(operation.targetRect) }
      }

    self.startedDrawingOperationsCount += drawingOperations.count

    if self.startedDrawingOperationsCount == self.currentDrawingOperations.count {
      self.currentDrawingOperations = self.pendingDrawingOperations
      self.pendingDrawingOperations = .init()
      self.startedDrawingOperationsCount = 0
    }

    var drawRuns = [DrawRun]()

    for drawingOperation in drawingOperations {
      switch drawingOperation {
      case let .draw(_, rectangle):
        for row in rectangle.rowsRange {
          var glyphsInRowCount = 0

          var latestHighlightCharacters = [Character]()
          var latestHighlightId: Int?
          func createDrawRun() {
            guard let id = latestHighlightId else {
              return
            }

            let highlight = state.highlights[id] ?? state.defaultHighlight
            let foregroundColor = highlight.foregroundColor?.cgColor ?? .white
            let backgroundColor = highlight.backgroundColor?.cgColor ?? .clear

            let font: NSFont = fontDerivatives.regular
            /* let fontIdentifier: String

             if highlight.bold {
               if highlight.italic {
                 font = fontDerivatives.boldItalic
                 fontIdentifier = "boldItalic"

               } else {
                 font = fontDerivatives.bold
                 fontIdentifier = "bold"
               }
             } else {
               if highlight.italic {
                 font = fontDerivatives.italic
                 fontIdentifier = "italic"

               } else {
                 font = fontDerivatives.regular
                 fontIdentifier = "regular"
               }
             }

             var hasher = Hasher()
             hasher.combine(latestHighlightCharacters)
             hasher.combine(fontIdentifier)
             let glyphRunCacheKey = latestHighlightCharacters.co */

            let glyphRunCacheKey = "\(latestHighlightCharacters)"
            let origin = GridPoint(row: row, column: rectangle.origin.column + glyphsInRowCount)

            let drawRun: DrawRun
            if let cachedGlyphRun = fontDerivatives.glyphRunCache.value(forKey: glyphRunCacheKey) {
              drawRun = DrawRun(
                origin: origin,
                characters: latestHighlightCharacters,
                glyphRun: cachedGlyphRun,
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor
              )

            } else {
              let newDrawRun = DrawRun.make(
                origin: origin,
                characters: latestHighlightCharacters,
                font: font,
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor
              )
              fontDerivatives.glyphRunCache.set(value: newDrawRun.glyphRun, forKey: glyphRunCacheKey)
              drawRun = newDrawRun
            }

            drawRuns.append(drawRun)

            glyphsInRowCount += drawRun.glyphRun.glyphs.count
          }

          for column in rectangle.columnsRange {
            guard column < window.frame.size.columnsCount else {
              continue
            }

            let index = GridPoint(row: row, column: column)
            let cell = window.grid[index]
            let newCharacters: [Character]
            if let cell {
              if let cellCharacter = cell.character {
                newCharacters = [cellCharacter]

              } else {
                newCharacters = []
              }

            } else {
              newCharacters = [" "]
            }

            if let id = latestHighlightId {
              if id == cell?.hlID {
                latestHighlightCharacters += newCharacters
                continue

              } else {
                createDrawRun()
              }
            }

            latestHighlightId = cell?.hlID
            latestHighlightCharacters = newCharacters
          }

          createDrawRun()
        }

        for drawRun in drawRuns {
          context.cgContext.setFillColor(drawRun.backgroundColor)

          let rectangle = GridRectangle(
            origin: drawRun.origin,
            size: .init(rowsCount: 1, columnsCount: drawRun.glyphRun.glyphs.count)
          )
          let rect = CellsGeometry.upsideDownRect(
            from: CellsGeometry.cellsRect(for: rectangle, cellSize: cellSize),
            parentViewHeight: self.bounds.height
          )
          context.cgContext.fill([rect])

          context.cgContext.textMatrix = .identity
          context.cgContext.setTextDrawingMode(.fill)
          context.cgContext.setFillColor(drawRun.foregroundColor)

          let glyphRun = drawRun.glyphRun

          CTFontDrawGlyphs(
            glyphRun.font,
            glyphRun.glyphs,
            glyphRun.positionsWithOffset(
              dx: cellSize.width * Double(drawRun.origin.column),
              dy: cellSize.height * Double(window.frame.size.rowsCount - drawRun.origin.row) - drawRun.glyphRun.font.ascender
            ),
            glyphRun.glyphs.count,
            context.cgContext
          )
        }

      case let .copy(from, to, size, _):
        let fromRect = CGRect(origin: from, size: size)
        let rep = self.bitmapImageRepForCachingDisplay(in: fromRect)!
        self.cacheDisplay(in: fromRect, to: rep)

        context.cgContext.draw(
          rep.cgImage!,
          in: .init(
            origin: to,
            size: size
          )
        )
      }
    }

    if let cursorPosition = state.cursorPosition(gridID: self.gridID), self.needsToDraw(CellsGeometry.cellRect(for: cursorPosition, cellSize: cellSize)) {
      context.cgContext.setFillColor(state.defaultHighlight.foregroundColor?.cgColor ?? .white)
      context.cgContext.setBlendMode(.exclusion)

      let rect = CellsGeometry.upsideDownRect(
        from: CellsGeometry.cellRect(
          for: cursorPosition,
          cellSize: cellSize
        ),
        parentViewHeight: self.bounds.height
      )
      context.cgContext.fill([rect])
    }

    if self.needsSynchronization {
      self.needsSynchronization = false

      context.flushGraphics()
    }
  }

  @MainActor
  func enque(drawingRequest: DrawingRequest) {
    guard let window = self.state.windows[gridID] else { return }

    switch drawingRequest {
    case let .draw(rectangle):
      self.pendingDrawingOperations.append(
        .draw(self.rect(for: rectangle), rectangle)
      )

    case let .copy(fromRectangle, originDelta):
      let toRectangle = GridRectangle(
        origin: fromRectangle.origin - originDelta,
        size: fromRectangle.size
      )
      .intersection(.init(origin: .init(), size: window.grid.size))
      guard let toRectangle else { break }

      let toRect = self.rect(for: toRectangle)

      let clampedFromRectangle = GridRectangle(
        origin: toRectangle.origin + originDelta,
        size: toRectangle.size
      )

      self.pendingDrawingOperations.append(
        .copy(
          from: CellsGeometry.cellOrigin(
            for: toRectangle.origin + originDelta,
            cellSize: self.state.fontDerivatives.cellSize
          ),
          to: toRect.origin,
          size: toRect.size,
          toRectangle: clampedFromRectangle
        )
      )
    }
  }

  @MainActor
  func flush() {
    guard !self.needsSynchronization, !self.currentDrawingOperations.isEmpty else {
      return
    }

    /* if self.currentDrawingOperations.isEmpty {
       self.currentDrawingOperations = self.pendingDrawingOperations
       self.pendingDrawingOperations = .init()
       self.startedDrawingOperationsCount = 0
     } */

    for currentDrawingOperation in self.currentDrawingOperations {
      self.setNeedsDisplay(currentDrawingOperation.targetRect)
    }

    self.needsSynchronization = true
  }

  @MainActor
  private var pendingDrawingOperations = Deque<DrawingOperation>()
  @MainActor
  private var currentDrawingOperations = Deque<DrawingOperation>()
  @MainActor
  private var startedDrawingOperationsCount = 0

  private var needsSynchronization = false

  @MainActor
  private func rect(for rectangle: GridRectangle) -> CGRect {
    let fontDerivatives = self.state.fontDerivatives

    return CellsGeometry.upsideDownRect(
      from: CellsGeometry.cellsRect(
        for: rectangle,
        cellSize: fontDerivatives.cellSize
      ),
      parentViewHeight: self.bounds.height
    )
//    return CellsGeometry.insetForDrawing(
//      rect: CellsGeometry.upsideDownRect(
//        from: CellsGeometry.cellsRect(
//          for: rectangle,
//          cellSize: fontDerivatives.cellSize
//        ),
//        parentViewHeight: self.bounds.height
//      ),
//      cellSize: fontDerivatives.cellSize,
//      boundingRectForFont: fontDerivatives.regular.boundingRectForFont
//    )
  }
}
