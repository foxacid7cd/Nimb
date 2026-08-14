// SPDX-License-Identifier: MIT

// Driven from GridLayer, which stays off the main actor because CALayer's
// overrides are nonisolated. The types here are explicitly nonisolated so the
// app target's MainActor default does not reach them.

import AppKit
import CoreText
import Metal
import NimbCore
import NimbState

final nonisolated class GridMetalRenderer: @unchecked Sendable {
  static let shared = GridMetalRenderer()

  private static let shaderSource = #"""
  #include <metal_stdlib>
  using namespace metal;

  struct QuadInstance {
    float2 origin;
    float2 size;
    float4 color;
  };

  struct GlyphInstance {
    float2 origin;
    float2 size;
    float2 uvOrigin;
    float2 uvSize;
    float4 color;
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
    constant Uniforms &uniforms [[buffer(1)]]
  ) {
    QuadInstance instance = instances[instanceID];
    float2 corner = quadCorners[vertexID];
    float2 point = instance.origin + corner * instance.size;
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
    constant Uniforms &uniforms [[buffer(1)]]
  ) {
    GlyphInstance instance = instances[instanceID];
    float2 corner = quadCorners[vertexID];
    float2 point = instance.origin + corner * instance.size;
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
}
