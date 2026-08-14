// SPDX-License-Identifier: MIT

// Driven from GridLayer, which stays off the main actor because CALayer's
// overrides are nonisolated. The types here are explicitly nonisolated so the
// app target's MainActor default does not reach them.

import AppKit
import CoreText
import Metal
import NimbCore
import NimbState

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

/// Unchecked because MTLDevice and the pipeline states are unannotated SDK
/// protocols. Everything here is immutable after init.
