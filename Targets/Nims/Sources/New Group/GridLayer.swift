//
//  GridLayer.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 08.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Library
import Quartz

class GridLayer: CALayer {
  override init(layer: Any) {
    super.init(layer: layer)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  struct ViewState {
    var id: Int
    var state: State
    var window: State.Window
    var fontDerivatives: StateDerivatives.Font
  }

  var viewState: ViewState? {
    didSet {
      guard let viewState else { return }

      self.backgroundColor = viewState.state.defaultHighlight.backgroundColor?.cgColor ?? .clear
    }
  }

  @MainActor
  func setNeedsDrawing(_ rectangle: GridRectangle) {
    let rect = CellsGeometry.upsideDownRect(
      from: CellsGeometry.cellsRect(
        for: rectangle,
        cellSize: self.viewState!.fontDerivatives.cellSize
      ),
      parentViewHeight: self.bounds.height
    )

    self.setNeedsDisplay(rect)
  }

  @MainActor
  override func draw(in context: CGContext) {
    context.saveGState()
    defer { context.restoreGState() }

    context.setAllowsAntialiasing(true)

    let rect = context.boundingBoxOfClipPath

    let rectangle = CellsGeometry.gridRectangle(
      cellsRect: CellsGeometry.upsideDownRect(from: rect, parentViewHeight: self.bounds.height),
      cellSize: self.viewState!.fontDerivatives.cellSize
    )
    .intersection(.init(origin: .init(), size: self.viewState!.window.grid.size))
    guard let rectangle = rectangle else { return }

    let cursorPosition = self.viewState!.state.cursorPosition(gridID: self.viewState!.id)

    var drawRuns = [DrawRun]()

    for row in rectangle.rowsRange {
      var glyphsInRowCount = 0

      var latestHighlightCharacters = [Character]()
      var latestHighlightId: Int?
      func createDrawRun() {
        guard let id = latestHighlightId else {
          return
        }

        let highlight = self.viewState!.state.highlights[id] ?? self.viewState!.state.defaultHighlight
        let foregroundColor = highlight.foregroundColor?.cgColor ?? .white
        let backgroundColor = highlight.backgroundColor?.cgColor ?? .clear

        let font: NSFont
        let fontIdentifier: String

        if highlight.bold {
          if highlight.italic {
            font = self.viewState!.fontDerivatives.boldItalic
            fontIdentifier = "boldItalic"

          } else {
            font = self.viewState!.fontDerivatives.bold
            fontIdentifier = "bold"
          }
        } else {
          if highlight.italic {
            font = self.viewState!.fontDerivatives.italic
            fontIdentifier = "italic"

          } else {
            font = self.viewState!.fontDerivatives.regular
            fontIdentifier = "regular"
          }
        }

        let glyphRunCacheKey = "\(fontIdentifier), \(latestHighlightCharacters)"

        let origin = GridPoint(row: row, column: rectangle.origin.column + glyphsInRowCount)

        let drawRun: DrawRun
        if let cachedGlyphRun = self.viewState!.fontDerivatives.glyphRunCache.value(forKey: glyphRunCacheKey) {
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
          self.viewState!.fontDerivatives.glyphRunCache.set(value: newDrawRun.glyphRun, forKey: glyphRunCacheKey)
          drawRun = newDrawRun
        }

        drawRuns.append(drawRun)

        glyphsInRowCount += drawRun.glyphRun.glyphs.count
      }

      for column in rectangle.columnsRange {
        guard column < self.viewState!.window.frame.size.columnsCount else {
          continue
        }

        let index = GridPoint(row: row, column: column)
        let cell = self.viewState!.window.grid[index]
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

      for drawRun in drawRuns {
        context.setFillColor(drawRun.backgroundColor)

        let rectangle = GridRectangle(
          origin: drawRun.origin,
          size: .init(rowsCount: 1, columnsCount: drawRun.glyphRun.glyphs.count)
        )
        let rect = CellsGeometry.upsideDownRect(
          from: CellsGeometry.cellsRect(
            for: rectangle,
            cellSize: self.viewState!.fontDerivatives.cellSize
          ),
          parentViewHeight: self.bounds.height
        )
        context.fill([rect])

        context.saveGState()

        context.setTextDrawingMode(.fill)
        context.setFillColor(drawRun.foregroundColor)
        context.textMatrix = .identity

        let glyphRun = drawRun.glyphRun

        CTFontDrawGlyphs(
          glyphRun.font,
          glyphRun.glyphs,
          glyphRun.positionsWithOffset(
            dx: self.viewState!.fontDerivatives.cellSize.width * Double(drawRun.origin.column),
            dy: self.viewState!.fontDerivatives.cellSize.height * Double(self.viewState!.window.grid.size.rowsCount - drawRun.origin.row) - drawRun.glyphRun.font.ascender
          ),
          glyphRun.glyphs.count,
          context
        )

        context.restoreGState()
      }
    }

    if let cursorPosition, cursorPosition.row >= rectangle.origin.row, cursorPosition.column >= rectangle.origin.column, cursorPosition.row < rectangle.origin.row + rectangle.size.rowsCount, cursorPosition.column < rectangle.origin.column + rectangle.size.columnsCount {
      context.setFillColor(self.viewState!.state.defaultHighlight.foregroundColor?.cgColor ?? .white)
      context.setBlendMode(.exclusion)

      let rect = CellsGeometry.upsideDownRect(
        from: CellsGeometry.cellRect(
          for: cursorPosition,
          cellSize: self.viewState!.fontDerivatives.cellSize
        ),
        parentViewHeight: self.bounds.height
      )
      context.fill([rect])
    }
  }
}
