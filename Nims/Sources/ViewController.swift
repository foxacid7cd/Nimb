// Copyright © 2022 foxacid7cd. All rights reserved.

import Cocoa
import Collections
import Combine
import SwiftUI

class ViewController: NSHostingController<ViewController.View> {
  init(viewModel: ViewModel) {
    self.viewModel = viewModel
    super.init(rootView: .init(viewModel))

    sizingOptions = [.preferredContentSize]
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  struct View: SwiftUI.View {
    init(_ viewModel: ViewModel) {
      self.viewModel = viewModel
    }

    var body: some SwiftUI.View {
      GeometryReader { proxy in
        ForEach(viewModel.grids) { grid in
          Canvas(opaque: false) { graphicsContext, size in
            for (y, row) in grid.rows.enumerated() {
              let frame = CGRect(
                origin: .init(
                  x: 0,
                  y: Double(y) * viewModel.rowHeight
                ),
                size: .init(
                  width: grid.frame.width,
                  height: viewModel.rowHeight
                )
              )

              graphicsContext.fill(
                Path(frame),
                with: .color(viewModel.defaultBackgroundColor),
                style: .init(
                  eoFill: true,
                  antialiased: false
                )
              )
              graphicsContext.draw(.init(row.attributedString), in: frame)
            }
          }
          .frame(width: grid.frame.width, height: grid.frame.height)
          .position(.init(x: grid.frame.midX, y: grid.frame.midY))
        }
      }
      .frame(
        width: viewModel.outerSize.width,
        height: viewModel.outerSize.height
      )
      .transaction { transaction in
        transaction.disablesAnimations = true
      }
    }

    private var viewModel: ViewModel
  }

  func set(viewModel: ViewModel) {
    self.viewModel = viewModel

    rootView = .init(viewModel)
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

              cgContext.setShouldAntialias(true)
              cgContext.setFillColor(glyphRun.foregroundColor.cgColor)

              CTFontDrawGlyphs(
                glyphRun.font,
                glyphRun.glyphs,
                glyphRun.positionsWithOffset(
                  dx: drawRun.cgFrame.origin.x,
                  dy: drawRun.cgFrame.origin.y + cellSize.height - glyphRun.font.ascender
                ),
                glyphRun.glyphs.count,
                cgContext
              )
            }
          }
        }
      }
    }

    func drawGridLine(startingAt origin: Point, width: Int) async {
//      let cellSize = await store.cellSize
//      self.cellSize = cellSize
//
//      for yOffset in 0 ..< rectangle.size.height {
//        let y = rectangle.origin.y + yOffset
//        let origin = Point(x: rectangle.origin.x, y: y)
//
//        let invertedY = await grid.frame.size.height - y - 1
//        let invertedOrigin = Point(x: rectangle.origin.x, y: invertedY)
//
//        let rowRectangle = Rectangle(
//          origin: invertedOrigin,
//          size: .init(
//            width: rectangle.size.width,
//            height: 1
//          )
//        )
//        let cgFrame = rowRectangle * cellSize
//
//        let attributedString = await grid.rowAttributedString(
//          startingAt: origin,
//          length: rectangle.size.width,
//          store: store
//        )
//        let drawRun = DrawRun.make(
//          origin: invertedOrigin,
//          cgFrame: cgFrame,
//          attributedString: attributedString
//        )
//
//        drawRuns.append(drawRun)
//        setNeedsDisplay(cgFrame)
//      }
    }

    private let store: Store
    private var drawRuns = [DrawRun]()
    private var cellSize = CGSize(width: 1, height: 1)
  }

  private var viewModel: ViewModel

  private var hostingView: NSHostingView<View> {
    view as! NSHostingView<View>
  }
}
