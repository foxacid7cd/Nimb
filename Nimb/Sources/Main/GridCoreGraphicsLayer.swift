// SPDX-License-Identifier: MIT

// Nonisolated for the same reason GridLayer is: CALayer's initialisers and
// draw(in:) are nonisolated in the SDK.

import AppKit
import NimbCore
import NimbState
import QuartzCore
import Synchronization

/// Draws a grid with CoreGraphics and CoreText. A plain CALayer, since only
/// that allocates a backing store and calls draw(in:).
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

  /// Unlike the Metal path, the dirty rects are load bearing: draw(in:) gets
  /// them as the context's clip.
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
