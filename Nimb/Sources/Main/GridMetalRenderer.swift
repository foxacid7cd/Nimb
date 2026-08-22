// SPDX-License-Identifier: MIT

// Driven from GridLayer, which stays off the main actor because CALayer's
// overrides are nonisolated. The types here are explicitly nonisolated so the
// app target's MainActor default does not reach them.

import AppKit
import CoreText
import Metal
import NimbCore
import Synchronization

final nonisolated class GridMetalRenderer: @unchecked Sendable {
  static let shared = GridMetalRenderer()

  private static let shaderSource = #"""
  #include <metal_stdlib>
  using namespace metal;

  struct QuadInstance {
    float2 origin;
    float2 size;
    float4 color;
    float rowSlot;
  };

  struct GlyphInstance {
    float2 origin;
    float2 size;
    float2 uvOrigin;
    float2 uvSize;
    float4 color;
    float rowSlot;
  };

  struct Uniforms {
    float2 viewportSize;
  };

  struct QuadOut {
    float4 position [[position]];
    float4 color;
  };

  struct GlyphOut {
    float4 position [[position]];
    float2 uv;
    float4 color;
  };

  constant float2 quadCorners[4] = {
    float2(0.0, 0.0),
    float2(1.0, 0.0),
    float2(0.0, 1.0),
    float2(1.0, 1.0)
  };

  vertex QuadOut quadVertex(
    uint vertexID [[vertex_id]],
    uint instanceID [[instance_id]],
    constant QuadInstance *instances [[buffer(0)]],
    constant Uniforms &uniforms [[buffer(1)]],
    constant float *rowOffsets [[buffer(2)]]
  ) {
    QuadInstance instance = instances[instanceID];
    float2 corner = quadCorners[vertexID];
    float2 origin = float2(
      instance.origin.x,
      instance.origin.y + rowOffsets[uint(instance.rowSlot)]
    );
    float2 point = origin + corner * instance.size;
    float2 ndc = float2(
      (point.x / uniforms.viewportSize.x) * 2.0 - 1.0,
      (point.y / uniforms.viewportSize.y) * 2.0 - 1.0
    );

    QuadOut out;
    out.position = float4(ndc, 0.0, 1.0);
    out.color = instance.color;
    return out;
  }

  fragment float4 quadFragment(QuadOut in [[stage_in]]) {
    return in.color;
  }

  vertex GlyphOut glyphVertex(
    uint vertexID [[vertex_id]],
    uint instanceID [[instance_id]],
    constant GlyphInstance *instances [[buffer(0)]],
    constant Uniforms &uniforms [[buffer(1)]],
    constant float *rowOffsets [[buffer(2)]]
  ) {
    GlyphInstance instance = instances[instanceID];
    float2 corner = quadCorners[vertexID];
    float2 origin = float2(
      instance.origin.x,
      instance.origin.y + rowOffsets[uint(instance.rowSlot)]
    );
    float2 point = origin + corner * instance.size;
    float2 ndc = float2(
      (point.x / uniforms.viewportSize.x) * 2.0 - 1.0,
      (point.y / uniforms.viewportSize.y) * 2.0 - 1.0
    );

    GlyphOut out;
    out.position = float4(ndc, 0.0, 1.0);
    out.uv = instance.uvOrigin + float2(
      corner.x * instance.uvSize.x,
      corner.y * instance.uvSize.y
    );
    out.color = instance.color;
    return out;
  }

  fragment float4 glyphFragment(
    GlyphOut in [[stage_in]],
    texture2d<float> atlasTexture [[texture(0)]],
    sampler atlasSampler [[sampler(0)]]
  ) {
    float alpha = atlasTexture.sample(atlasSampler, in.uv).r;
    return float4(in.color.rgb, in.color.a * alpha);
  }
  """#

  let device: MTLDevice
  let commandQueue: MTLCommandQueue
  let quadPipelineState: MTLRenderPipelineState
  let glyphPipelineState: MTLRenderPipelineState
  let glyphSamplerState: MTLSamplerState

  /// One atlas per backing scale, shared by every grid.
  ///
  /// Each atlas is a 4096x4096 r8Unorm texture, so 16MB. They used to be owned
  /// by GridMetalSceneBuilder, one per GridView, which meant a window with
  /// eight splits held eight of them and rasterized every glyph eight times.
  /// The contents are identical by construction — the key is (font, glyph) and
  /// nothing about it is per-grid — so there was never a reason to duplicate.
  private let glyphAtlases = Mutex<[Int: GridMetalGlyphAtlas]>([:])

  init?(device: MTLDevice? = MTLCreateSystemDefaultDevice()) {
    guard
      let device,
      let commandQueue = device.makeCommandQueue()
    else {
      return nil
    }

    let library: MTLLibrary
    do {
      library = try device.makeLibrary(source: Self.shaderSource, options: nil)
    } catch {
      logger.error("Metal shader compilation failed: \(error.localizedDescription)")
      return nil
    }

    guard
      let quadVertex = library.makeFunction(name: "quadVertex"),
      let quadFragment = library.makeFunction(name: "quadFragment"),
      let glyphVertex = library.makeFunction(name: "glyphVertex"),
      let glyphFragment = library.makeFunction(name: "glyphFragment")
    else {
      logger.error("Metal shader entry points missing")
      return nil
    }

    let quadPipelineState: MTLRenderPipelineState
    do {
      quadPipelineState = try Self.makePipelineState(
        device: device,
        vertexFunction: quadVertex,
        fragmentFunction: quadFragment,
      )
    } catch {
      logger.error("Metal quad pipeline creation failed: \(error.localizedDescription)")
      return nil
    }

    let glyphPipelineState: MTLRenderPipelineState
    do {
      glyphPipelineState = try Self.makePipelineState(
        device: device,
        vertexFunction: glyphVertex,
        fragmentFunction: glyphFragment,
      )
    } catch {
      logger.error("Metal glyph pipeline creation failed: \(error.localizedDescription)")
      return nil
    }

    let samplerDescriptor = MTLSamplerDescriptor()
    samplerDescriptor.minFilter = .linear
    samplerDescriptor.magFilter = .linear
    samplerDescriptor.sAddressMode = .clampToEdge
    samplerDescriptor.tAddressMode = .clampToEdge

    guard let glyphSamplerState = device.makeSamplerState(descriptor: samplerDescriptor) else {
      logger.error("Metal sampler creation failed")
      return nil
    }

    self.device = device
    self.commandQueue = commandQueue
    self.quadPipelineState = quadPipelineState
    self.glyphPipelineState = glyphPipelineState
    self.glyphSamplerState = glyphSamplerState
  }

  private static func makePipelineState(
    device: MTLDevice,
    vertexFunction: MTLFunction,
    fragmentFunction: MTLFunction,
  ) throws
  -> MTLRenderPipelineState {
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.vertexFunction = vertexFunction
    descriptor.fragmentFunction = fragmentFunction
    descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    descriptor.colorAttachments[0].isBlendingEnabled = true
    descriptor.colorAttachments[0].rgbBlendOperation = .add
    descriptor.colorAttachments[0].alphaBlendOperation = .add
    descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
    descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
    descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
    descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
    return try device.makeRenderPipelineState(descriptor: descriptor)
  }

  /// The atlas for `scale`, created on first use.
  ///
  /// The atlas itself is not internally synchronised: its entry table and shelf
  /// packer are plain stored properties. Every caller reaches it from scene
  /// building, which runs on one thread at a time, so the lock here only
  /// guards the lookup.
  func glyphAtlas(scale: CGFloat) -> GridMetalGlyphAtlas? {
    // Quantised so float noise in backingScaleFactor cannot mint a second
    // 16MB atlas for what is really the same scale.
    let key = Int((max(scale, 1) * 1000).rounded())

    return glyphAtlases.withLock { atlases in
      if let existing = atlases[key] {
        return existing
      }
      guard let atlas = GridMetalGlyphAtlas(renderer: self, scale: scale) else {
        return nil
      }
      atlases[key] = atlas
      return atlas
    }
  }
}
