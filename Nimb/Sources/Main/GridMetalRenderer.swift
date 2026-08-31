// SPDX-License-Identifier: MIT

// Explicitly nonisolated, so the app target's MainActor default does not reach
// types driven from GridLayer's nonisolated CALayer overrides.

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
    // Coverage is blended in a nonlinear space, where a half covered pixel
    // reads as much darker than half. Light glyphs on a dark ground lose
    // weight from that and dark glyphs on a light one gain it, so the curve
    // leans on the glyph's own luminance. CoreGraphics corrects text the same
    // way when it composites a mask itself.
    float luminance = dot(in.color.rgb, float3(0.2126, 0.7152, 0.0722));
    alpha = pow(alpha, mix(1.15, 0.72, luminance));
    return float4(in.color.rgb, in.color.a * alpha);
  }
  """#

  let device: MTLDevice
  let commandQueue: MTLCommandQueue
  let quadPipelineState: MTLRenderPipelineState
  let glyphPipelineState: MTLRenderPipelineState
  let glyphSamplerState: MTLSamplerState

  /// One 16MB atlas per backing scale, shared by every grid. The key is
  /// (font, glyph), so per-grid copies would be identical by construction.
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
    // One texel per pixel, so there is nothing to interpolate between: linear
    // filtering could only soften a glyph that is off by a rounding error.
    samplerDescriptor.minFilter = .nearest
    samplerDescriptor.magFilter = .nearest
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

  /// The atlas for `scale`, created on first use. The atlas itself is not
  /// synchronised, so the lock guards only the lookup; callers are serialised.
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
