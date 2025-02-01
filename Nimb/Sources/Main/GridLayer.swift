// SPDX-License-Identifier: MIT

import Algorithms
import AppKit
import Collections
import ConcurrencyExtras
import CustomDump
import Queue

public class GridLayer: CALayer, Rendering, @unchecked Sendable {
  private let gridID: Grid.ID
  private let store: Store

  @MainActor
  public var grid: Grid? {
    guard isRendered else {
      return nil
    }
    return state.grids[gridID]
  }

  @MainActor
  private var upsideDownTransform: CGAffineTransform? {
    guard let grid else {
      return nil
    }
    return .init(scaleX: 1, y: -1)
      .translatedBy(x: 0, y: -Double(grid.rowsCount) * state.font.cellHeight)
  }

  override public init(layer: Any) {
    let gridLayer = layer as! GridLayer
    gridID = gridLayer.gridID
    store = gridLayer.store
    super.init(layer: layer)
  }

  @MainActor
  init(
    store: Store,
    gridID: Grid.ID
  ) {
    self.store = store
    self.gridID = gridID
    super.init()

    masksToBounds = true
    drawsAsynchronously = true
    needsDisplayOnBoundsChange = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func draw(in ctx: CGContext) {
    MainActor.assumeIsolated {
      guard isRendered, let grid, let upsideDownTransform else {
        return
      }

      ctx.saveGState()
      defer { ctx.restoreGState() }

      let boundingRect = IntegerRectangle(
        frame: ctx.boundingBoxOfClipPath.applying(upsideDownTransform),
        cellSize: state.font.cellSize
      )

      ctx.setAllowsAntialiasing(false)
      ctx.setAllowsFontSmoothing(false)
      ctx.setShouldAntialias(false)
      ctx.setShouldSmoothFonts(false)
      grid.drawRuns.drawBackground(
        to: ctx,
        boundingRect: boundingRect,
        font: state.font,
        appearance: state.appearance,
        upsideDownTransform: upsideDownTransform
      )

      ctx.setAllowsAntialiasing(true)
      ctx.setAllowsFontSmoothing(true)
      ctx.setShouldAntialias(true)
      ctx.setShouldSmoothFonts(true)
      grid.drawRuns.drawForeground(
        to: ctx,
        boundingRect: boundingRect,
        font: state.font,
        appearance: state.appearance,
        upsideDownTransform: upsideDownTransform
      )

      if
        state.cursorBlinkingPhase,
        state.isMouseUserInteractionEnabled,
        let cursorDrawRun = grid.drawRuns.cursorDrawRun,
        boundingRect.contains(cursorDrawRun.origin)
      {
        cursorDrawRun.draw(
          to: ctx,
          font: state.font,
          appearance: state.appearance,
          upsideDownTransform: upsideDownTransform
        )
      }
    }
  }

  @MainActor
  public func render() {
    for dirtyRect in calculateDirtyRects() {
      setNeedsDisplay(dirtyRect)
    }
    displayIfNeeded()
  }

  @MainActor
  private func calculateDirtyRects() -> [CGRect] {
    guard isRendered, let grid, let upsideDownTransform else {
      return []
    }

    if updates.isFontUpdated || updates.isAppearanceUpdated {
      return [bounds]
    }

    var dirtyRects: [CGRect] = []

    if let gridUpdate = updates.gridUpdates[gridID] {
      switch gridUpdate {
      case let .dirtyRectangles(value):
        for rectangle in value {
          dirtyRects.append(
            (rectangle * state.font.cellSize)
              .insetBy(dx: -state.font.cellSize.width, dy: -state.font.cellSize.height * 0.5)
              .applying(upsideDownTransform)
          )
        }

      case .needsDisplay:
        return [bounds]
      }
    }

    if
      let cursorDrawRun = grid.drawRuns.cursorDrawRun,
      updates.isCursorBlinkingPhaseUpdated || updates.isMouseUserInteractionEnabledUpdated
    {
      dirtyRects.append(
        (cursorDrawRun.rectangle * state.font.cellSize)
          .applying(upsideDownTransform)
      )
    }

    return dirtyRects
  }
}

extension CGContext: @unchecked @retroactive Sendable { }
