// SPDX-License-Identifier: MIT

// Explicitly nonisolated: the app target defaults to MainActor, and the whole
// point of this type is to run off it.

import AppKit
import Metal
import NimbCore
import NimbState
import Synchronization

/// One grid's contribution to a frame, captured on the main actor.
///
/// `frame` is in the grids container's coordinates and `needsRebuild` is the
/// caller's answer to whether anything about this grid changed. A grid that
/// only moved arrives with needsRebuild false and keeps the scene it already
/// had, because scenes are held in grid-local coordinates.
nonisolated struct GridsRenderEntry: @unchecked Sendable {
  let id: Grid.ID
  let snapshot: GridDrawSnapshot
  let frame: CGRect
  let needsRebuild: Bool
}

/// Unchecked because it carries a CALayer. Only `update(frame:)` is reached off
/// the main thread, and that writes a Mutex; `bounds` and `contentsScale` are
/// captured on the main actor at submit time so the drain never reads them.
nonisolated struct GridsRenderRequest: @unchecked Sendable {
  /// Back to front, matching the order walkingGridFrames yields.
  let entries: [GridsRenderEntry]
  /// Grids still alive, so scenes for the rest can be dropped.
  let liveGridIDs: Set<Grid.ID>
  let bounds: CGRect
  let scale: CGFloat
  let clearColor: MTLClearColor
  let target: GridsMetalLayer
}

/// Turns a frame's worth of grid snapshots into one combined Metal frame, away
/// from the main actor.
///
/// This replaced a per-grid queue when the grids stopped having a layer each.
/// The coalescing is now per frame rather than per grid, which is simpler and
/// stricter: a frame that is superseded before the drain reaches it is dropped
/// whole, so grids can never reach the screen from two different frames.
final nonisolated class GridsSceneBuildQueue: Sendable {
  private struct Storage {
    var pending: GridsRenderRequest? = nil
    var isDraining = false
  }

  /// Unchecked because it is plain mutable state: it is only ever touched from
  /// the single drain task, which is what makes one drain task rather than one
  /// per grid worth having.
  private final class Cache: @unchecked Sendable {
    var builders: [Grid.ID: GridMetalSceneBuilder] = [:]
    var scenes: [Grid.ID: GridMetalScene] = [:]
  }

  static let shared = GridsSceneBuildQueue()

  private let storage = Mutex(Storage())
  private let cache = Cache()

  private init() { }

  private static func append<T>(_ values: [T], to combined: inout [T]) -> Range<Int> {
    let start = combined.count
    combined.append(contentsOf: values)
    return start ..< combined.count
  }

  /// Scissor rects are in pixels with the origin at the top left of the render
  /// target, while the grid frame is in points with the origin at the bottom
  /// left of the container -- hence the flip.
  private static func scissorRect(
    for frame: CGRect,
    containerHeight: CGFloat,
    scale: CGFloat,
    drawableWidth: Int,
    drawableHeight: Int,
  )
  -> MTLScissorRect? {
    let minX = Int((frame.minX * scale).rounded(.down))
    let minY = Int(((containerHeight - frame.maxY) * scale).rounded(.down))
    let maxX = Int((frame.maxX * scale).rounded(.up))
    let maxY = Int(((containerHeight - frame.minY) * scale).rounded(.up))

    let clampedMinX = max(0, min(minX, drawableWidth))
    let clampedMinY = max(0, min(minY, drawableHeight))
    let clampedMaxX = max(clampedMinX, min(maxX, drawableWidth))
    let clampedMaxY = max(clampedMinY, min(maxY, drawableHeight))

    guard clampedMaxX > clampedMinX, clampedMaxY > clampedMinY else {
      return nil
    }

    return .init(
      x: clampedMinX,
      y: clampedMinY,
      width: clampedMaxX - clampedMinX,
      height: clampedMaxY - clampedMinY,
    )
  }

  @MainActor
  func submit(_ request: GridsRenderRequest) {
    let shouldStartDraining = storage.withLock { state in
      state.pending = request
      guard !state.isDraining else {
        return false
      }
      state.isDraining = true
      return true
    }

    if shouldStartDraining {
      Task { await drain() }
    }
  }

  /// Explicitly off the main actor. A bare `Task {}` started from `submit`
  /// would inherit its MainActor isolation and put the whole build back where
  /// it came from.
  @concurrent
  private func drain() async {
    while true {
      let request = storage.withLock { state -> GridsRenderRequest? in
        guard let pending = state.pending else {
          // Cleared under the same lock submit checks, so a request arriving
          // now starts a new drain rather than being left for one that is
          // already returning.
          state.isDraining = false
          return nil
        }
        state.pending = nil
        return pending
      }
      guard let request else {
        return
      }

      guard let frame = makeFrame(for: request) else {
        continue
      }
      request.target.update(frame: frame)
      await MainActor.run {
        request.target.render()
      }
    }
  }

  private func makeFrame(for request: GridsRenderRequest) -> GridsPreparedMetalFrame? {
    guard let renderer = GridMetalRenderer.shared else {
      return nil
    }

    // Grids that went away take their cached scene and builder with them.
    // Builders hold the previous frame's instance counts, so a stale one is
    // only wasted memory, but scenes are the large part.
    cache.scenes = cache.scenes.filter { request.liveGridIDs.contains($0.key) }
    cache.builders = cache.builders.filter { request.liveGridIDs.contains($0.key) }

    var scene = GridMetalScene()
    var draws = [GridMetalDraw]()
    draws.reserveCapacity(request.entries.count)

    let scale = max(request.scale, 1)
    let drawableWidth = Int(ceil(request.bounds.width * scale))
    let drawableHeight = Int(ceil(request.bounds.height * scale))

    for entry in request.entries {
      let builder: GridMetalSceneBuilder
      if let existing = cache.builders[entry.id] {
        builder = existing
      } else {
        builder = GridMetalSceneBuilder(renderer: renderer)
        cache.builders[entry.id] = builder
      }

      if entry.needsRebuild || cache.scenes[entry.id] == nil {
        cache.scenes[entry.id] = builder.makeScene(
          snapshot: entry.snapshot,
          bounds: .init(origin: .zero, size: entry.frame.size),
          scale: scale,
        )
      }
      guard let gridScene = cache.scenes[entry.id] else {
        continue
      }

      guard
        let scissorRect = Self.scissorRect(
          for: entry.frame,
          containerHeight: request.bounds.height,
          scale: scale,
          drawableWidth: drawableWidth,
          drawableHeight: drawableHeight,
        )
      else {
        // Entirely outside the drawable. Metal rejects a scissor rect that
        // leaves the render target, so such a grid is dropped rather than
        // clamped to a degenerate one.
        continue
      }

      var draw = GridMetalDraw(
        origin: .init(Float(entry.frame.origin.x), Float(entry.frame.origin.y)),
        scissorRect: scissorRect,
      )
      draw.backgroundQuads = Self.append(gridScene.backgroundQuads, to: &scene.backgroundQuads)
      draw.decorationQuads = Self.append(gridScene.decorationQuads, to: &scene.decorationQuads)
      draw.glyphInstances = Self.append(gridScene.glyphInstances, to: &scene.glyphInstances)
      draw.cursorQuads = Self.append(gridScene.cursorQuads, to: &scene.cursorQuads)
      draw.cursorGlyphInstances = Self.append(gridScene.cursorGlyphInstances, to: &scene.cursorGlyphInstances)
      draws.append(draw)
    }

    // Read after building: placing a glyph can overflow the atlas, which
    // replaces its texture rather than clearing it in place.
    guard let atlasTexture = renderer.glyphAtlas(scale: scale)?.texture else {
      return nil
    }

    return .init(
      scene: scene,
      draws: draws,
      atlasTexture: atlasTexture,
      clearColor: request.clearColor,
    )
  }
}
