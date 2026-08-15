// SPDX-License-Identifier: MIT

// Nonisolated for the same reason GridLayer is: CALayer's initialisers and
// draw(in:) are nonisolated in the SDK, so an isolated subclass cannot override
// them.

import AppKit
import NimbCore
import NimbState
import QuartzCore
import Synchronization

/// Draws a grid with CoreGraphics and CoreText.
///
/// A plain CALayer, deliberately: CALayer's display machinery allocates a
/// backing store and calls draw(in:), which is what a CAMetalLayer does not do
/// -- its contents come from presented drawables. GridLayer's Metal-unavailable
/// fallback tried to draw this way into itself and silently produced nothing.
public final nonisolated class GridCoreGraphicsLayer: CALayer {
  private let gridID: Grid.ID
  private nonisolated let isolatedRenderInput = Mutex<GridRenderInput?>(nil)

  override public init(layer: Any) {
    let gridLayer = layer as! GridCoreGraphicsLayer
    gridID = gridLayer.gridID
    super.init(layer: layer)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @MainActor
  init(gridID: Grid.ID) {
    self.gridID = gridID
    super.init()

    masksToBounds = true
    needsDisplayOnBoundsChange = true
    isOpaque = false
  }

  override public func draw(in ctx: CGContext) {
    guard let snapshot = isolatedRenderInput.withLock({ $0?.snapshot }) else {
      return
    }

    GridCoreGraphicsRenderer.draw(
      snapshot: snapshot,
      in: ctx,
      clipRect: ctx.boundingBoxOfClipPath,
    )
  }

  nonisolated func update(renderInput: GridRenderInput?) {
    isolatedRenderInput.withLock { $0 = renderInput }
  }

  /// Unlike the Metal path, the dirty rects here are load bearing: draw(in:)
  /// receives them as the context's clip, and only the rows they touch are
  /// redrawn.
  nonisolated func render() {
    guard let renderInput = isolatedRenderInput.withLock({ $0 }) else {
      return
    }

    for dirtyRect in GridCoreGraphicsRenderer.dirtyRects(
      renderInput: renderInput,
      gridID: gridID,
      bounds: bounds,
    ) {
      let clippedDirtyRect = dirtyRect.intersection(bounds)
      guard !clippedDirtyRect.isNull, !clippedDirtyRect.isEmpty else {
        continue
      }
      setNeedsDisplay(clippedDirtyRect)
    }
  }
}
