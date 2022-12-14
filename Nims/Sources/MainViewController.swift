// Copyright © 2022 foxacid7cd. All rights reserved.

import Cocoa
import Collections

@MainActor
class MainViewController: NSViewController {
  init(store: Store) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    view = NSView(frame: .zero)
  }

  func apply(_ update: Store.Update) async {
    switch update {
    case .cellSize:
      for view in view.subviews {
        guard let gridView = view as? GridView else {
          continue
        }

        await updateFrame(for: gridView, with: gridView.grid)
      }

    case let .newGrid(grid):
      let gridView = GridView(store: store, grid: grid)
      await updateFrame(for: gridView, with: grid)

      view.addSubview(gridView)

      for await gridUpdate in grid.updates {
        guard !Task.isCancelled else {
          return
        }

        switch gridUpdate {
        case .size:
          await updateFrame(for: gridView, with: grid)

        case let .row(origin, width):
          let rectangle = Rectangle(
            origin: origin,
            size: .init(
              width: width,
              height: 1
            )
          )
          await gridView.drawGrid(at: rectangle)
        }
      }
    }
  }

  @MainActor
  private class GridView: NSView {
    init(store: Store, grid: Grid) {
      self.store = store
      self.grid = grid
      super.init(frame: .init())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    let grid: Grid

    override func draw(_: NSRect) {
      guard let graphicsContext = NSGraphicsContext.current else {
        assertionFailure()
        return
      }
      let cgContext = graphicsContext.cgContext

      cgContext.saveGState()
      defer { cgContext.restoreGState() }

      let rects = rectsBeingDrawn()

      for rect in rects {
        for (index, drawRun) in drawRuns.enumerated().reversed() {
          if rect.contains(drawRun.cgFrame) {
            drawRuns.remove(at: index)

            for glyphRun in drawRun.glyphRuns {
              cgContext.setShouldAntialias(false)
              cgContext.setFillColor(glyphRun.backgroundColor.cgColor)

              let backgroundRect = glyphRun.rectangle * cellSize
              cgContext.fill([backgroundRect])

              graphicsContext.cgContext.setShouldAntialias(true)
              graphicsContext.cgContext.setFillColor(glyphRun.foregroundColor.cgColor)

              CTFontDrawGlyphs(
                glyphRun.font,
                glyphRun.glyphs,
                glyphRun.positionsWithOffset(
                  dx: drawRun.cgFrame.origin.x,
                  dy: drawRun.cgFrame.origin.y + cellSize.height - glyphRun.font.ascender
                ),
                glyphRun.glyphs.count,
                graphicsContext.cgContext
              )
            }
          }
        }
      }
    }

    func drawGrid(at rectangle: Rectangle) async {
      let cellSize = await store.cellSize
      self.cellSize = cellSize

      for yOffset in 0 ..< rectangle.size.height {
        let y = rectangle.origin.y + yOffset
        let origin = Point(x: rectangle.origin.x, y: y)

        let invertedY = grid.size.height - y - 1
        let invertedOrigin = Point(x: rectangle.origin.x, y: invertedY)

        let rowRectangle = Rectangle(
          origin: invertedOrigin,
          size: .init(
            width: rectangle.size.width,
            height: 1
          )
        )
        let cgFrame = rowRectangle * cellSize

        let attributedString = await grid.rowAttributedString(
          startingAt: origin,
          length: rectangle.size.width,
          store: store
        )
        let drawRun = DrawRun.make(
          origin: invertedOrigin,
          cgFrame: cgFrame,
          attributedString: attributedString
        )

        drawRuns.append(drawRun)
        setNeedsDisplay(cgFrame)
      }
    }

    private let store: Store
    private var drawRuns = [DrawRun]()
    private var cellSize = CGSize(width: 1, height: 1)
  }

  private let store: Store
  private var updatesTask: Task<Void, Never>?

  private func updateFrame(for gridView: GridView, with grid: Grid) async {
    let gridSize = grid.size
    let cellSize = await store.cellSize

    let size = gridSize * cellSize
    gridView.frame = .init(
      origin: .init(),
      size: size
    )

    if grid.id == 1 {
      set(preferredContentSize: size)
    }
  }

  private func set(preferredContentSize: CGSize) {
    self.preferredContentSize = preferredContentSize
  }
}
