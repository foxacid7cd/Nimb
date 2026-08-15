// SPDX-License-Identifier: MIT

// Nonisolated for the same reason GridLayer is: CALayer's drawing entry points
// are nonisolated in the SDK.

import AppKit
import NimbCore
import NimbState

/// The CoreGraphics/CoreText drawing, shared by both layers.
///
/// GridLayer used to own this as private methods and fall back to it when Metal
/// was unavailable, by letting CALayer's display machinery call draw(in:). That
/// never actually painted -- a CAMetalLayer's contents come from its drawables,
/// so the fallback produced an empty grid. Drawing with CoreGraphics needs a
/// plain layer, which is what GridCoreGraphicsLayer is for.
nonisolated enum GridCoreGraphicsRenderer {
  static func draw(
    snapshot: GridDrawSnapshot,
    in ctx: CGContext,
    clipRect: CGRect,
  ) {
    ctx.saveGState()
    defer { ctx.restoreGState() }

    let boundingRect = IntegerRectangle(
      frame: clipRect.applying(snapshot.upsideDownTransform),
      cellSize: snapshot.font.cellSize,
    )
    let visibleRowDrawRuns = snapshot.grid.drawRuns.visibleRowDrawRuns(
      boundingRect: boundingRect,
      font: snapshot.font,
      upsideDownTransform: snapshot.upsideDownTransform,
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
          appearance: snapshot.appearance,
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
          appearance: snapshot.appearance,
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
        upsideDownTransform: snapshot.upsideDownTransform,
      )
    }
  }

  static func dirtyRects(
    renderInput: GridRenderInput,
    gridID: Grid.ID,
    bounds: CGRect,
  )
    -> [CGRect]
  {
    let snapshot = renderInput.snapshot
    let grid = snapshot.grid
    let upsideDownTransform = CGAffineTransform(scaleX: 1, y: -1)
      .translatedBy(x: 0, y: -Double(grid.rowsCount) * snapshot.font.cellHeight)

    if renderInput.updates.isFontUpdated || renderInput.updates.isAppearanceUpdated {
      return [bounds]
    }

    var dirtyRects: [CGRect] = []

    if let gridUpdate = renderInput.updates.gridUpdates[gridID] {
      switch gridUpdate {
      case let .dirtyRectangles(value):
        for rectangle in value {
          dirtyRects.append(
            (rectangle * snapshot.font.cellSize)
              .insetBy(
                dx: -snapshot.font.cellSize.width,
                dy: -snapshot.font.cellSize.height * 0.5,
              )
              .applying(upsideDownTransform),
          )
        }

      case .needsDisplay:
        return [bounds]
      }
    }

    if
      let cursorDrawRun = grid.drawRuns.cursorDrawRun,
      renderInput.updates.isCursorBlinkingPhaseUpdated || renderInput.updates.isMouseUserInteractionEnabledUpdated
    {
      dirtyRects.append(
        (cursorDrawRun.rectangle * snapshot.font.cellSize)
          .applying(upsideDownTransform),
      )
    }

    return dirtyRects
  }
}
