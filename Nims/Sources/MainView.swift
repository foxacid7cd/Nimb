//
//  MainView.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import Cocoa
import Collections
import OSLog

class MainView: NSView {
  init(nimsAppearance: NimsAppearance) {
    self.nimsAppearance = nimsAppearance

    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func gridResize(gridID: Int, gridSize: GridSize) {
    if gridID == 1 {
      self.outerGridSize = gridSize

      for gridView in self.gridViews.values {
        gridView.outerGridSize = gridSize

        gridView.updateViewFrame()
      }
    }

    let gridView = self.gridView(gridID: gridID)

    gridView.gridSize = gridSize
    gridView.updateViewFrame()

    if gridView.superview == nil {
      addSubview(gridView)
    }
  }

  func gridLine(gridID: Int, origin: GridPoint, cells: [Cell]) {
    guard let gridView = gridViews[gridID] else {
      return
    }

    gridView.gridLine(origin: origin, cells: cells)
  }

  func gridClear(gridID: Int) {
    guard let gridView = gridViews[gridID] else {
      return
    }

    gridView.gridClear()
  }

  func winPos(gridID: Int, winRef: WinRef, winFrame: GridRectangle) {
    let gridView = self.gridView(gridID: gridID)

    gridView.winRef = winRef
    gridView.winFrame = winFrame
    gridView.updateViewFrame()

    addSubview(gridView)
  }

  private var nimsAppearance: NimsAppearance
  private var gridViews = PersistentDictionary<Int, GridView>()
  private var outerGridSize = GridSize()

  private func gridView(gridID: Int) -> GridView {
    if let gridView = gridViews[gridID] {
      return gridView

    } else {
      let gridView = GridView(nimsAppearance: nimsAppearance)
      self.gridViews[gridID] = gridView

      gridView.outerGridSize = self.outerGridSize
      return gridView
    }
  }
}

private class GridView: NSView {
  init(nimsAppearance: NimsAppearance) {
    self.nimsAppearance = nimsAppearance

    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var gridSize = GridSize()
  var winRef: WinRef?
  var winFrame: GridRectangle?
  var outerGridSize = GridSize()

  var gridFrame: GridRectangle {
    if let winFrame {
      return .init(
        origin: .init(
          x: winFrame.origin.x,
          y: outerGridSize.height - winFrame.origin.y - winFrame.size.height
        ),
        size: winFrame.size
      )
    }

    return .init(size: gridSize)
  }

  override func draw(_ dirtyRect: NSRect) {
    let context = NSGraphicsContext.current!

    context.saveGraphicsState()
    defer { context.restoreGraphicsState() }

    context.cgContext.setFillColor(self.nimsAppearance.defaultBackgroundColor.cgColor)
    context.cgContext.fill([dirtyRect])

    var filteredDrawRuns = Deque<DrawRun>()
    defer { self.drawRuns = filteredDrawRuns }

    for drawRun in self.drawRuns {
      guard dirtyRect.contains(drawRun.rect) else {
        filteredDrawRuns.append(drawRun)

        continue
      }

      for glyphRun in drawRun.glyphRuns {
        context.cgContext.setShouldAntialias(false)
        context.cgContext.setFillColor(glyphRun.backgroundColor.cgColor)

        let backgroundGridRectangle = GridRectangle(
          origin: .init(x: drawRun.gridOrigin.x + glyphRun.stringRange.location, y: drawRun.gridOrigin.y),
          size: .init(width: glyphRun.stringRange.length + 1, height: 1)
        )
        let backgroundRect = (backgroundGridRectangle * self.nimsAppearance.cellSize)

        context.cgContext.fill([backgroundRect])

        context.cgContext.setShouldAntialias(true)
        context.cgContext.setFillColor(glyphRun.foregroundColor.cgColor)

        CTFontDrawGlyphs(
          glyphRun.font,
          glyphRun.glyphs,
          glyphRun.positionsWithOffset(
            dx: drawRun.rect.origin.x,
            dy: drawRun.rect.origin.y + self.nimsAppearance.cellSize.height - self.nimsAppearance.regularFont.ascender
          ),
          glyphRun.glyphs.count,
          context.cgContext
        )
      }
    }
  }

  func gridLine(origin: GridPoint, cells: [Cell]) {
    let cellSize = self.nimsAppearance.cellSize

    let origin = GridPoint(
      x: origin.x,
      y: self.gridSize.height - origin.y - 1
    )

    let gridRectangle = GridRectangle(
      origin: origin,
      size: .init(
        width: cells.count,
        height: 1
      )
    )
    let rect = gridRectangle * cellSize

    let accumulator = NSMutableAttributedString()

    let string = NSMutableString()
    var previousCell = cells[0]

    for (cellIndex, cell) in cells.enumerated() {
      if cell.hlID == previousCell.hlID, cellIndex != cells.count - 1 {
        if let character = cell.character {
          string.append(String(character))
        }

      } else {
        let attributedString = NSAttributedString(
          string: string as String,
          attributes: nimsAppearance.stringAttributes(hlID: previousCell.hlID)
        )
        accumulator.append(attributedString)

        string.setString(cell.character.map { String($0) } ?? "")
      }

      previousCell = cell
    }

    let drawRun = DrawRun.make(
      gridOrigin: origin,
      rect: rect,
      attributedString: accumulator
    )

    self.drawRuns.append(drawRun)
    setNeedsDisplay(rect)
  }

  func gridClear() {
    setNeedsDisplay(bounds)
  }

  func updateViewFrame() {
    frame = self.gridFrame * self.nimsAppearance.cellSize
  }

  private var nimsAppearance: NimsAppearance
  private var drawRuns = Deque<DrawRun>()
}
