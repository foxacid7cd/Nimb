// SPDX-License-Identifier: MIT

// Driven from GridLayer, which stays off the main actor because CALayer's
// overrides are nonisolated. The types here are explicitly nonisolated so the
// app target's MainActor default does not reach them.

import AppKit
import CoreText
import Metal
import NimbState

/// Everything drawing one grid needs, captured as values on the main actor so
/// the drawing itself can happen anywhere.
struct GridDrawSnapshot: Sendable {
  let grid: Grid
  let upsideDownTransform: CGAffineTransform
  let font: Font
  let appearance: Appearance
  let cursorBlinkingPhase: Bool
  let isMouseUserInteractionEnabled: Bool
}

/// One grid's slice of a combined scene: where its instances live in the shared
/// arrays, where it sits in the shared layer, and what it may paint over.
///
/// The five ranges have to be drawn grid by grid rather than kind by kind
/// across all grids. Batching by kind would put a grid behind another grid's
/// glyphs on top of the front grid's background.
nonisolated struct GridMetalDraw {
  var origin: SIMD2<Float>
  var scissorRect: MTLScissorRect
  var backgroundQuads: Range<Int> = 0 ..< 0
  var decorationQuads: Range<Int> = 0 ..< 0
  var glyphInstances: Range<Int> = 0 ..< 0
  var cursorQuads: Range<Int> = 0 ..< 0
  var cursorGlyphInstances: Range<Int> = 0 ..< 0
}

/// Unchecked because MTLTexture is an unannotated SDK protocol. The frame is
/// built on one thread and consumed on another, and Metal objects are
/// documented as safe for this.
nonisolated struct GridsPreparedMetalFrame: @unchecked Sendable {
  /// Every visible grid's instances, concatenated.
  let scene: GridMetalScene
  /// Back to front, matching the order walkingGridFrames yields.
  let draws: [GridMetalDraw]
  let atlasTexture: MTLTexture
  let clearColor: MTLClearColor
}

struct GridMetalQuadInstance {
  var origin: SIMD2<Float>
  var size: SIMD2<Float>
  var color: SIMD4<Float>
}

struct GridMetalGlyphInstance {
  var origin: SIMD2<Float>
  var size: SIMD2<Float>
  var uvOrigin: SIMD2<Float>
  var uvSize: SIMD2<Float>
  var color: SIMD4<Float>
}

struct GridMetalScene {
  var backgroundQuads: [GridMetalQuadInstance] = []
  var decorationQuads: [GridMetalQuadInstance] = []
  var glyphInstances: [GridMetalGlyphInstance] = []
  var cursorQuads: [GridMetalQuadInstance] = []
  var cursorGlyphInstances: [GridMetalGlyphInstance] = []
}

/// How large each of a scene's arrays turned out to be. Carried from one frame
/// to the next so the arrays can be sized once instead of grown by doubling.
nonisolated struct GridMetalSceneCounts {
  var backgroundQuads = 0
  var decorationQuads = 0
  var glyphInstances = 0
  var cursorQuads = 0
  var cursorGlyphInstances = 0

  init() { }

  init(scene: GridMetalScene) {
    backgroundQuads = scene.backgroundQuads.count
    decorationQuads = scene.decorationQuads.count
    glyphInstances = scene.glyphInstances.count
    cursorQuads = scene.cursorQuads.count
    cursorGlyphInstances = scene.cursorGlyphInstances.count
  }

  func reserve(in scene: inout GridMetalScene) {
    scene.backgroundQuads.reserveCapacity(backgroundQuads)
    scene.decorationQuads.reserveCapacity(decorationQuads)
    scene.glyphInstances.reserveCapacity(glyphInstances)
    scene.cursorQuads.reserveCapacity(cursorQuads)
    scene.cursorGlyphInstances.reserveCapacity(cursorGlyphInstances)
  }
}

// Unchecked because MTLDevice and the pipeline states are unannotated SDK
// protocols. Everything here is immutable after init.
