// SPDX-License-Identifier: MIT

// Explicitly nonisolated, so the app target's MainActor default does not reach
// types driven from GridLayer's nonisolated CALayer overrides.

import AppKit
import CoreText
import Metal

/// Unchecked because MTLTexture is an unannotated SDK protocol, though Metal
/// documents it as safe to build on one thread and consume on another.
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
  /// How far each row slot has moved since its instances were built. The shader
  /// adds it, so scrolling a row costs one float. Slot zero is reserved.
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
