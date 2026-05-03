// SPDX-License-Identifier: MIT

import Algorithms
import Collections
import ConcurrencyExtras
import CustomDump
import AppKit
import Queue
import Synchronization

public class GridLayer: CALayer, Rendering, @unchecked Sendable {
  private struct DrawSnapshot {
    let grid: Grid
    let upsideDownTransform: CGAffineTransform
    let font: Font
    let appearance: Appearance
    let cursorBlinkingPhase: Bool
    let isMouseUserInteractionEnabled: Bool
  }

  private let gridID: Grid.ID
  private let store: Store
  private nonisolated let isolatedRenderContext = Mutex<RenderContext?>(nil)

  @MainActor
  public var isRendered: Bool {
    isolatedRenderContext.withLock { $0 != nil }
  }

  @MainActor
  public var renderContext: RenderContext {
    isolatedRenderContext.withLock { $0! }
  }

  @MainActor
  public func update(renderContext: RenderContext) {
    isolatedRenderContext.withLock { $0 = renderContext }
  }

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
    guard let snapshot: DrawSnapshot = isolatedRenderContext.withLock({ renderContext in
      guard
        let renderContext,
        let grid = renderContext.state.grids[gridID]
      else {
        return nil
      }

      let upsideDownTransform = CGAffineTransform(scaleX: 1, y: -1)
        .translatedBy(x: 0, y: -Double(grid.rowsCount) * renderContext.state.font.cellHeight)

      return DrawSnapshot(
        grid: grid,
        upsideDownTransform: upsideDownTransform,
        font: renderContext.state.font,
        appearance: renderContext.state.appearance,
        cursorBlinkingPhase: renderContext.state.cursorBlinkingPhase,
        isMouseUserInteractionEnabled: renderContext.state.isMouseUserInteractionEnabled
      )
    }) else {
      return
    }

    ctx.saveGState()
    defer { ctx.restoreGState() }

    let boundingRect = IntegerRectangle(
      frame: ctx.boundingBoxOfClipPath.applying(snapshot.upsideDownTransform),
      cellSize: snapshot.font.cellSize
    )
    let visibleRowDrawRuns = snapshot.grid.drawRuns.visibleRowDrawRuns(
      boundingRect: boundingRect,
      font: snapshot.font,
      upsideDownTransform: snapshot.upsideDownTransform
    )

    ctx.setAllowsAntialiasing(false)
    ctx.setAllowsFontSmoothing(false)
    ctx.setShouldAntialias(false)
    ctx.setShouldSmoothFonts(false)
    for rowDrawRuns in visibleRowDrawRuns {
      for visibleDrawRun in rowDrawRuns.drawRuns {
        visibleDrawRun.drawRun.drawBackground(
          to: ctx,
          at: visibleDrawRun.rect.origin,
          font: snapshot.font,
          appearance: snapshot.appearance
        )
      }
    }

    ctx.setAllowsAntialiasing(true)
    ctx.setAllowsFontSmoothing(true)
    ctx.setShouldAntialias(true)
    ctx.setShouldSmoothFonts(true)
    for rowDrawRuns in visibleRowDrawRuns {
      for visibleDrawRun in rowDrawRuns.drawRuns {
        visibleDrawRun.drawRun.drawForeground(
          to: ctx,
          at: visibleDrawRun.rect,
          font: snapshot.font,
          appearance: snapshot.appearance
        )
      }
    }

    if
      snapshot.cursorBlinkingPhase,
      snapshot.isMouseUserInteractionEnabled,
      let cursorDrawRun = snapshot.grid.drawRuns.cursorDrawRun,
      boundingRect.contains(cursorDrawRun.origin)
    {
      cursorDrawRun.draw(
        to: ctx,
        font: snapshot.font,
        appearance: snapshot.appearance,
        upsideDownTransform: snapshot.upsideDownTransform
      )
    }
  }

  @MainActor
  public func render() {
    for dirtyRect in coalesceDirtyRects(calculateDirtyRects()) {
      setNeedsDisplay(dirtyRect)
    }
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

  @MainActor
  private func coalesceDirtyRects(_ dirtyRects: [CGRect]) -> [CGRect] {
    guard dirtyRects.count > 1 else {
      return dirtyRects
    }

    let padding = CGSize(width: state.font.cellWidth, height: state.font.cellHeight * 0.5)
    var coalescedRects: [CGRect] = []

    for dirtyRect in dirtyRects {
      var mergedRect = dirtyRect.intersection(bounds)
      guard !mergedRect.isNull, !mergedRect.isEmpty else {
        continue
      }

      var index = 0
      while index < coalescedRects.count {
        let expandedCoalescedRect = coalescedRects[index].insetBy(dx: -padding.width, dy: -padding.height)
        if expandedCoalescedRect.intersects(mergedRect) {
          mergedRect = mergedRect.union(coalescedRects.remove(at: index))
        } else {
          index += 1
        }
      }

      coalescedRects.append(mergedRect)
    }

    return coalescedRects
  }
}

extension CGContext: @unchecked @retroactive Sendable { }
