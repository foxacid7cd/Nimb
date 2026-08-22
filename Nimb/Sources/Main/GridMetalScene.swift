// SPDX-License-Identifier: MIT

// Driven from GridLayer, which stays off the main actor because CALayer's
// overrides are nonisolated. The types here are explicitly nonisolated so the
// app target's MainActor default does not reach them.

import AppKit
import CoreText
import Metal

/// Unchecked because MTLTexture is an unannotated SDK protocol. The frame is
/// built on one thread and consumed on another, and Metal objects are
/// documented as safe for this.
nonisolated struct GridPreparedMetalFrame: @unchecked Sendable {
  let scene: GridMetalScene
  let atlasTexture: MTLTexture
  let clearColor: MTLClearColor
}

struct GridMetalQuadInstance {
  var origin: SIMD2<Float>
  var size: SIMD2<Float>
  var color: SIMD4<Float>
  /// Index into the scene's row offsets. Stable for the life of a cached row,
  /// so a row that scrolls never has its instances rewritten.
  var rowSlot: Float
}

struct GridMetalGlyphInstance {
  var origin: SIMD2<Float>
  var size: SIMD2<Float>
  var uvOrigin: SIMD2<Float>
  var uvSize: SIMD2<Float>
  var color: SIMD4<Float>
  var rowSlot: Float
}

struct GridMetalScene {
  /// How far each row slot has moved since its instances were built, in
  /// points. The shader adds it, so scrolling a row costs one float here
  /// rather than a rewrite of every instance the row owns.
  ///
  /// Slot zero is reserved and always zero, for instances that belong to no
  /// row -- the cursor.
  var rowOffsets: [Float] = [0]
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
