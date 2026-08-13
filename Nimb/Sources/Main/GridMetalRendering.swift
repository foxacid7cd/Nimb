// SPDX-License-Identifier: MIT

import AppKit
import CoreText
import Metal

struct GridPreparedMetalFrame: @unchecked Sendable {
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

final class GridMetalRenderer: @unchecked Sendable {
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

  static let shared = GridMetalRenderer()

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

private final class GridMetalGlyphAtlas: @unchecked Sendable {
  struct GlyphKey: Hashable {
    let fontName: String
    let pointSize: CGFloat
    let glyph: CGGlyph
    let scaleMillipoints: Int
  }

  struct GlyphEntry {
    let origin: SIMD2<Float>
    let size: SIMD2<Float>
    let uvOrigin: SIMD2<Float>
    let uvSize: SIMD2<Float>
  }

  private struct RasterizedGlyph {
    let bytes: [UInt8]
    let width: Int
    let height: Int
    let origin: SIMD2<Float>
    let size: SIMD2<Float>
  }

  let texture: MTLTexture
  let scale: CGFloat

  private var entries: [GlyphKey: GlyphEntry] = [:]
  private var nextX = 0
  private var nextY = 0
  private var rowHeight = 0

  init?(renderer: GridMetalRenderer, scale: CGFloat, size: Int = 4096) {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .r8Unorm,
      width: size,
      height: size,
      mipmapped: false,
    )
    descriptor.usage = [.shaderRead]
    descriptor.storageMode = renderer.device.hasUnifiedMemory ? .shared : .managed

    guard let texture = renderer.device.makeTexture(descriptor: descriptor) else {
      return nil
    }

    self.texture = texture
    self.scale = scale

    let zero = [UInt8](repeating: 0, count: size * size)
    texture.replace(
      region: .init(origin: .init(x: 0, y: 0, z: 0), size: .init(width: size, height: size, depth: 1)),
      mipmapLevel: 0,
      withBytes: zero,
      bytesPerRow: size,
    )
  }

  func entry(for glyph: CGGlyph, font: NSFont) -> GlyphEntry? {
    let key = GlyphKey(
      fontName: font.fontName,
      pointSize: font.pointSize,
      glyph: glyph,
      scaleMillipoints: Int((scale * 1000).rounded()),
    )
    if let entry = entries[key] {
      return entry
    }

    guard let rasterizedGlyph = rasterizeGlyph(glyph: glyph, font: font) else {
      return nil
    }

    return place(rasterizedGlyph: rasterizedGlyph, for: key)
  }

  private func rasterizeGlyph(glyph: CGGlyph, font: NSFont) -> RasterizedGlyph? {
    let ctFont = font as CTFont
    var glyph = glyph
    var bounds = CTFontGetBoundingRectsForGlyphs(ctFont, .default, &glyph, nil, 1)

    if bounds.isNull || bounds.isInfinite {
      bounds = .zero
    }

    let paddingPoints = 1 / max(scale, 1)
    let paddedBounds = bounds.insetBy(dx: -paddingPoints, dy: -paddingPoints)
    let pixelWidth = max(1, Int(ceil(paddedBounds.width * scale)))
    let pixelHeight = max(1, Int(ceil(paddedBounds.height * scale)))
    var bytes = [UInt8](repeating: 0, count: pixelWidth * pixelHeight)

    guard
      let context = CGContext(
        data: &bytes,
        width: pixelWidth,
        height: pixelHeight,
        bitsPerComponent: 8,
        bytesPerRow: pixelWidth,
        space: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGImageAlphaInfo.none.rawValue,
      )
    else {
      return nil
    }

    context.setFillColor(gray: 1, alpha: 1)
    context.translateBy(x: 0, y: CGFloat(pixelHeight))
    context.scaleBy(x: scale, y: -scale)
    context.translateBy(x: -paddedBounds.minX, y: -paddedBounds.minY)

    if let path = CTFontCreatePathForGlyph(ctFont, glyph, nil) {
      context.addPath(path)
      context.fillPath()
    }

    return .init(
      bytes: bytes,
      width: pixelWidth,
      height: pixelHeight,
      origin: .init(Float(paddedBounds.minX), Float(paddedBounds.minY)),
      size: .init(Float(CGFloat(pixelWidth) / scale), Float(CGFloat(pixelHeight) / scale)),
    )
  }

  private func place(
    rasterizedGlyph: RasterizedGlyph,
    for key: GlyphKey,
  ) -> GlyphEntry? {
    if rasterizedGlyph.width > texture.width || rasterizedGlyph.height > texture.height {
      return nil
    }

    if nextX + rasterizedGlyph.width > texture.width {
      nextX = 0
      nextY += rowHeight
      rowHeight = 0
    }

    if nextY + rasterizedGlyph.height > texture.height {
      reset()
    }

    if nextX + rasterizedGlyph.width > texture.width || nextY + rasterizedGlyph.height > texture.height {
      return nil
    }

    texture.replace(
      region: .init(
        origin: .init(x: nextX, y: nextY, z: 0),
        size: .init(width: rasterizedGlyph.width, height: rasterizedGlyph.height, depth: 1),
      ),
      mipmapLevel: 0,
      withBytes: rasterizedGlyph.bytes,
      bytesPerRow: rasterizedGlyph.width,
    )

    let entry = GlyphEntry(
      origin: rasterizedGlyph.origin,
      size: rasterizedGlyph.size,
      uvOrigin: .init(
        Float(nextX) / Float(texture.width),
        Float(nextY) / Float(texture.height),
      ),
      uvSize: .init(
        Float(rasterizedGlyph.width) / Float(texture.width),
        Float(rasterizedGlyph.height) / Float(texture.height),
      ),
    )
    entries[key] = entry

    nextX += rasterizedGlyph.width + 1
    rowHeight = max(rowHeight, rasterizedGlyph.height + 1)

    return entry
  }

  private func reset() {
    entries.removeAll(keepingCapacity: true)
    nextX = 0
    nextY = 0
    rowHeight = 0

    let zero = [UInt8](repeating: 0, count: texture.width * texture.height)
    texture.replace(
      region: .init(origin: .init(x: 0, y: 0, z: 0), size: .init(width: texture.width, height: texture.height, depth: 1)),
      mipmapLevel: 0,
      withBytes: zero,
      bytesPerRow: texture.width,
    )
  }
}

final class GridMetalSceneBuilder: @unchecked Sendable {
  private let renderer: GridMetalRenderer
  private var glyphAtlas: GridMetalGlyphAtlas? = nil

  init(renderer: GridMetalRenderer) {
    self.renderer = renderer
  }

  func makeFrame(
    snapshot: GridDrawSnapshot,
    bounds: CGRect,
    scale: CGFloat,
  ) -> GridPreparedMetalFrame? {
    guard let glyphAtlas = prepareGlyphAtlas(scale: scale) else {
      return nil
    }

    return .init(
      scene: buildScene(snapshot: snapshot, bounds: bounds, glyphAtlas: glyphAtlas, scale: scale),
      atlasTexture: glyphAtlas.texture,
      clearColor: snapshot.appearance.defaultBackgroundColor.metalClearColor,
    )
  }

  private func prepareGlyphAtlas(scale: CGFloat) -> GridMetalGlyphAtlas? {
    if let glyphAtlas, abs(glyphAtlas.scale - scale) < 0.001 {
      return glyphAtlas
    }

    let glyphAtlas = GridMetalGlyphAtlas(renderer: renderer, scale: scale)
    self.glyphAtlas = glyphAtlas
    return glyphAtlas
  }

  private func buildScene(
    snapshot: GridDrawSnapshot,
    bounds: CGRect,
    glyphAtlas: GridMetalGlyphAtlas,
    scale: CGFloat,
  ) -> GridMetalScene {
    var scene = GridMetalScene()

    let boundingRect = IntegerRectangle(
      frame: bounds.applying(snapshot.upsideDownTransform),
      cellSize: snapshot.font.cellSize,
    )
    let visibleRowDrawRuns = snapshot.grid.drawRuns.visibleRowDrawRuns(
      boundingRect: boundingRect,
      font: snapshot.font,
      upsideDownTransform: snapshot.upsideDownTransform,
    )

    for rowDrawRuns in visibleRowDrawRuns {
      for visibleDrawRun in rowDrawRuns.drawRuns {
        let drawRun = visibleDrawRun.drawRun
        let rect = visibleDrawRun.rect
        scene.backgroundQuads.append(
          quadInstance(
            rect: rect,
            color: snapshot.appearance.backgroundColor(for: drawRun.highlightID).metal,
          ),
        )

        appendDecorationInstances(
          for: drawRun,
          rect: rect,
          font: snapshot.font,
          appearance: snapshot.appearance,
          scale: scale,
          to: &scene.decorationQuads,
        )

        if let glyphRuns = drawRun.glyphRuns {
          appendGlyphInstances(
            glyphRuns,
            in: rect,
            color: snapshot.appearance.foregroundColor(for: drawRun.highlightID).metal,
            glyphAtlas: glyphAtlas,
            to: &scene.glyphInstances,
          )
        }
      }
    }

    if
      snapshot.cursorBlinkingPhase,
      snapshot.isMouseUserInteractionEnabled,
      let cursorDrawRun = snapshot.grid.drawRuns.cursorDrawRun,
      boundingRect.contains(cursorDrawRun.origin)
    {
      appendCursorInstances(
        cursorDrawRun,
        snapshot: snapshot,
        glyphAtlas: glyphAtlas,
        to: &scene,
      )
    }

    return scene
  }

  private func appendGlyphInstances(
    _ glyphRuns: [GlyphRun],
    in rect: CGRect,
    color: SIMD4<Float>,
    glyphAtlas: GridMetalGlyphAtlas,
    clipRect: CGRect? = nil,
    to glyphInstances: inout [GridMetalGlyphInstance],
  ) {
    for glyphRun in glyphRuns {
      for index in glyphRun.glyphs.indices {
        guard let entry = glyphAtlas.entry(for: glyphRun.glyphs[index], font: glyphRun.appKitFont) else {
          continue
        }

        let glyphRect = CGRect(
          x: rect.origin.x + glyphRun.positions[index].x + CGFloat(entry.origin.x),
          y: rect.origin.y + glyphRun.positions[index].y + CGFloat(entry.origin.y),
          width: CGFloat(entry.size.x),
          height: CGFloat(entry.size.y),
        )

        if
          let clipRect,
          let clippedInstance = clippedGlyphInstance(
            rect: glyphRect,
            uvOrigin: entry.uvOrigin,
            uvSize: entry.uvSize,
            color: color,
            clipRect: clipRect,
          )
        {
          glyphInstances.append(clippedInstance)
        } else if clipRect == nil {
          glyphInstances.append(
            .init(
              origin: .init(Float(glyphRect.origin.x), Float(glyphRect.origin.y)),
              size: .init(Float(glyphRect.width), Float(glyphRect.height)),
              uvOrigin: entry.uvOrigin,
              uvSize: entry.uvSize,
              color: color,
            ),
          )
        }
      }
    }
  }

  private func appendCursorInstances(
    _ cursorDrawRun: CursorDrawRun,
    snapshot: GridDrawSnapshot,
    glyphAtlas: GridMetalGlyphAtlas,
    to scene: inout GridMetalScene,
  ) {
    let cursorForegroundColor: Color
    let cursorBackgroundColor: Color

    if cursorDrawRun.highlightID == .zero {
      cursorForegroundColor = snapshot.appearance.defaultBackgroundColor
      cursorBackgroundColor = snapshot.appearance.defaultForegroundColor
    } else {
      cursorForegroundColor = snapshot.appearance.foregroundColor(for: cursorDrawRun.highlightID)
      cursorBackgroundColor = snapshot.appearance.backgroundColor(for: cursorDrawRun.highlightID)
    }

    let offset = cursorDrawRun.origin * snapshot.font.cellSize
    let cursorRect = cursorDrawRun.cellFrame
      .offsetBy(dx: offset.x, dy: offset.y)
      .applying(snapshot.upsideDownTransform)

    scene.cursorQuads.append(
      quadInstance(rect: cursorRect, color: cursorBackgroundColor.metal),
    )

    if
      cursorDrawRun.shouldDrawParentText,
      let glyphRuns = cursorDrawRun.parentDrawRun.glyphRuns
    {
      let parentRectangle = IntegerRectangle(
        origin: .init(column: cursorDrawRun.parentOrigin.column, row: cursorDrawRun.parentOrigin.row),
        size: .init(columnsCount: cursorDrawRun.parentDrawRun.columnsCount, rowsCount: 1),
      )
      let parentRect = (parentRectangle * snapshot.font.cellSize)
        .applying(snapshot.upsideDownTransform)

      appendGlyphInstances(
        glyphRuns,
        in: parentRect,
        color: cursorForegroundColor.metal,
        glyphAtlas: glyphAtlas,
        clipRect: cursorRect,
        to: &scene.cursorGlyphInstances,
      )
    }
  }

  private func appendDecorationInstances(
    for drawRun: DrawRun,
    rect: CGRect,
    font: Font,
    appearance: Appearance,
    scale: CGFloat,
    to quads: inout [GridMetalQuadInstance],
  ) {
    guard case let .cells(cells) = drawRun.rowPartContent else {
      return
    }

    let decorations = appearance.decorations(for: drawRun.highlightID)
    guard decorations != .init() else {
      return
    }

    let color = appearance.specialColor(for: drawRun.highlightID).metal
    let thickness = max(1 / max(scale, 1), 0.5)
    let underlineY = rect.origin.y + 0.5

    if decorations.isStrikethrough {
      quads.append(
        quadInstance(
          rect: .init(x: rect.minX, y: rect.midY - thickness / 2, width: rect.width, height: thickness),
          color: color,
        ),
      )
    }

    if decorations.isUnderline {
      quads.append(
        quadInstance(
          rect: .init(x: rect.minX, y: underlineY, width: rect.width, height: thickness),
          color: color,
        ),
      )
    } else if decorations.isUnderdashed {
      appendPatternedLineQuads(
        fromX: rect.minX,
        toX: rect.maxX,
        y: underlineY,
        segmentWidth: 2,
        gapWidth: 2,
        thickness: thickness,
        color: color,
        to: &quads,
      )
    } else if decorations.isUnderdotted {
      appendPatternedLineQuads(
        fromX: rect.minX,
        toX: rect.maxX,
        y: underlineY,
        segmentWidth: 1,
        gapWidth: 1,
        thickness: thickness,
        color: color,
        to: &quads,
      )
    } else if decorations.isUnderdouble {
      quads.append(
        quadInstance(
          rect: .init(x: rect.minX, y: underlineY, width: rect.width, height: thickness),
          color: color,
        ),
      )
      quads.append(
        quadInstance(
          rect: .init(x: rect.minX, y: underlineY + 3, width: rect.width, height: thickness),
          color: color,
        ),
      )
    } else if decorations.isUndercurl {
      let widthDivider = 3
      let xStep = font.cellWidth / Double(widthDivider)
      let pointsCount = cells.count * widthDivider + 1
      let oddUnderlineY = underlineY + 3
      let evenUnderlineY = underlineY

      for index in 0 ..< pointsCount {
        let isEven = index.isMultiple(of: 2)
        let x = rect.minX + Double(index) * xStep
        let y = isEven ? evenUnderlineY : oddUnderlineY
        quads.append(
          quadInstance(
            rect: .init(x: x, y: y, width: thickness, height: thickness),
            color: color,
          ),
        )
      }
    }
  }

  private func appendPatternedLineQuads(
    fromX: CGFloat,
    toX: CGFloat,
    y: CGFloat,
    segmentWidth: CGFloat,
    gapWidth: CGFloat,
    thickness: CGFloat,
    color: SIMD4<Float>,
    to quads: inout [GridMetalQuadInstance],
  ) {
    var currentX = fromX
    while currentX < toX {
      let width = min(segmentWidth, toX - currentX)
      quads.append(
        quadInstance(
          rect: .init(x: currentX, y: y, width: width, height: thickness),
          color: color,
        ),
      )
      currentX += segmentWidth + gapWidth
    }
  }

  private func quadInstance(
    rect: CGRect,
    color: SIMD4<Float>,
  ) -> GridMetalQuadInstance {
    .init(
      origin: .init(Float(rect.origin.x), Float(rect.origin.y)),
      size: .init(Float(rect.width), Float(rect.height)),
      color: color,
    )
  }

  private func clippedGlyphInstance(
    rect: CGRect,
    uvOrigin: SIMD2<Float>,
    uvSize: SIMD2<Float>,
    color: SIMD4<Float>,
    clipRect: CGRect,
  ) -> GridMetalGlyphInstance? {
    let intersection = rect.intersection(clipRect)
    guard !intersection.isNull, !intersection.isEmpty, rect.width > 0, rect.height > 0 else {
      return nil
    }

    let left = Float((intersection.minX - rect.minX) / rect.width)
    let right = Float((rect.maxX - intersection.maxX) / rect.width)
    let bottom = Float((intersection.minY - rect.minY) / rect.height)
    let top = Float((rect.maxY - intersection.maxY) / rect.height)

    return .init(
      origin: .init(Float(intersection.origin.x), Float(intersection.origin.y)),
      size: .init(Float(intersection.width), Float(intersection.height)),
      uvOrigin: .init(
        uvOrigin.x + uvSize.x * left,
        uvOrigin.y + uvSize.y * top,
      ),
      uvSize: .init(
        uvSize.x * max(0, 1 - left - right),
        uvSize.y * max(0, 1 - top - bottom),
      ),
      color: color,
    )
  }
}

extension Color {
  var metal: SIMD4<Float> {
    let color = appKit.usingColorSpace(.deviceRGB) ?? appKit
    return .init(
      Float(color.redComponent),
      Float(color.greenComponent),
      Float(color.blueComponent),
      Float(color.alphaComponent),
    )
  }

  var metalClearColor: MTLClearColor {
    let metal = metal
    return .init(
      red: Double(metal.x),
      green: Double(metal.y),
      blue: Double(metal.z),
      alpha: Double(metal.w),
    )
  }
}
