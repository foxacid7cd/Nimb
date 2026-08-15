// SPDX-License-Identifier: MIT

// Nonisolated for the same reason GridsMetalLayer is: CALayer's initialisers
// and draw(in:) are nonisolated in the SDK, so an isolated subclass cannot
// override them.

import AppKit
import NimbCore
import NimbState
import QuartzCore
import Synchronization

/// Draws every grid with CoreGraphics and CoreText, as the control the Metal
/// path is measured against.
///
/// A plain CALayer, deliberately: CALayer's display machinery allocates a
/// backing store and calls draw(in:), which is what a CAMetalLayer does not do
/// -- its contents come from presented drawables.
///
/// It covers all the grids rather than one, mirroring the Metal layer, so the
/// two still render the same workload and the comparison stays honest.
public final nonisolated class GridsCoreGraphicsLayer: CALayer {
  struct Content: @unchecked Sendable {
    /// Back to front, matching the order walkingGridFrames yields.
    let entries: [GridsRenderEntry]
    let updates: State.Updates
    let backgroundColor: Color
    /// Set when the grids moved, appeared or went away. Per-grid dirty rects
    /// only describe content, and each grid used to get a repaint for free
    /// from its own layer's needsDisplayOnBoundsChange; sharing one layer
    /// means a grid that merely moved leaves its old pixels behind.
    let needsFullRedraw: Bool
  }

  private nonisolated let isolatedContent = Mutex<Content?>(nil)

  override public init(layer: Any) {
    super.init(layer: layer)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public init() {
    super.init()

    masksToBounds = true
    needsDisplayOnBoundsChange = true
    isOpaque = false
  }

  override public func draw(in ctx: CGContext) {
    guard let content = isolatedContent.withLock({ $0 }) else {
      return
    }

    let clipRect = ctx.boundingBoxOfClipPath
    ctx.setFillColor(content.backgroundColor.cg)
    ctx.fill(clipRect)

    for entry in content.entries {
      let gridClipRect = clipRect.intersection(entry.frame)
      guard !gridClipRect.isNull, !gridClipRect.isEmpty else {
        continue
      }

      ctx.saveGState()
      // Clipped as well as translated: the Metal path scissors each grid to
      // its frame, and without the same clip a grid would paint over its
      // neighbours.
      ctx.clip(to: gridClipRect)
      ctx.translateBy(x: entry.frame.origin.x, y: entry.frame.origin.y)

      GridCoreGraphicsRenderer.draw(
        snapshot: entry.snapshot,
        in: ctx,
        clipRect: gridClipRect.offsetBy(
          dx: -entry.frame.origin.x,
          dy: -entry.frame.origin.y,
        ),
      )
      ctx.restoreGState()
    }
  }

  nonisolated func update(content: Content?) {
    isolatedContent.withLock { $0 = content }
  }

  /// Unlike the Metal path, the dirty rects here are load bearing: draw(in:)
  /// receives them as the context's clip, and only the rows they touch are
  /// redrawn.
  nonisolated func render() {
    guard let content = isolatedContent.withLock({ $0 }) else {
      return
    }

    guard !content.needsFullRedraw else {
      setNeedsDisplay()
      return
    }

    for entry in content.entries {
      let dirtyRects = GridCoreGraphicsRenderer.dirtyRects(
        snapshot: entry.snapshot,
        updates: content.updates,
        gridID: entry.id,
        bounds: .init(origin: .zero, size: entry.frame.size),
      )

      for dirtyRect in dirtyRects {
        let clippedDirtyRect = dirtyRect
          .offsetBy(dx: entry.frame.origin.x, dy: entry.frame.origin.y)
          .intersection(bounds)
        guard !clippedDirtyRect.isNull, !clippedDirtyRect.isEmpty else {
          continue
        }
        setNeedsDisplay(clippedDirtyRect)
      }
    }
  }
}
