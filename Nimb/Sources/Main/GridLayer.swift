// SPDX-License-Identifier: MIT

import Algorithms
import Collections
import ConcurrencyExtras
import CoreText
import CustomDump
import AppKit
import Metal
import Queue
import QuartzCore
import Synchronization

public class GridLayer: CAMetalLayer, Rendering, @unchecked Sendable {
  private struct DrawSnapshot {
    let grid: Grid
    let upsideDownTransform: CGAffineTransform
    let font: Font
    let appearance: Appearance
    let cursorBlinkingPhase: Bool
    let isMouseUserInteractionEnabled: Bool
  }

  private struct MetalUniforms {
    var viewportSize: SIMD2<Float>
  }

  private struct MetalQuadInstance {
    var origin: SIMD2<Float>
    var size: SIMD2<Float>
    var color: SIMD4<Float>
  }

  private struct MetalGlyphInstance {
    var origin: SIMD2<Float>
    var size: SIMD2<Float>
    var uvOrigin: SIMD2<Float>
    var uvSize: SIMD2<Float>
    var color: SIMD4<Float>
  }

  private struct MetalScene {
    var backgroundQuads: [MetalQuadInstance] = []
    var glyphInstances: [MetalGlyphInstance] = []
    var cursorQuads: [MetalQuadInstance] = []
    var cursorGlyphInstances: [MetalGlyphInstance] = []
  }

  private final class MetalRenderer: @unchecked Sendable {
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
          fragmentFunction: quadFragment
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
          fragmentFunction: glyphFragment
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
      fragmentFunction: MTLFunction
    ) throws -> MTLRenderPipelineState {
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
        (1.0 - corner.y) * instance.uvSize.y
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
  }

  private final class MetalGlyphAtlas: @unchecked Sendable {
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

    let texture: MTLTexture
    let scale: CGFloat

    private var entries: [GlyphKey: GlyphEntry] = [:]
    private var nextX = 0
    private var nextY = 0
    private var rowHeight = 0

    init?(renderer: MetalRenderer, scale: CGFloat, size: Int = 4096) {
      let descriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .r8Unorm,
        width: size,
        height: size,
        mipmapped: false
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
        bytesPerRow: size
      )
    }

    func entry(
      for glyph: CGGlyph,
      font: NSFont,
      renderer: MetalRenderer
    ) -> GlyphEntry? {
      let key = GlyphKey(
        fontName: font.fontName,
        pointSize: font.pointSize,
        glyph: glyph,
        scaleMillipoints: Int((scale * 1000).rounded())
      )
      if let entry = entries[key] {
        return entry
      }

      guard let rasterizedGlyph = rasterizeGlyph(glyph: glyph, font: font) else {
        return nil
      }

      return place(rasterizedGlyph: rasterizedGlyph, for: key)
    }

    private struct RasterizedGlyph {
      let bytes: [UInt8]
      let width: Int
      let height: Int
      let origin: SIMD2<Float>
      let size: SIMD2<Float>
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
          bitmapInfo: CGImageAlphaInfo.none.rawValue
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
        size: .init(Float(CGFloat(pixelWidth) / scale), Float(CGFloat(pixelHeight) / scale))
      )
    }

    private func place(
      rasterizedGlyph: RasterizedGlyph,
      for key: GlyphKey
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
          size: .init(width: rasterizedGlyph.width, height: rasterizedGlyph.height, depth: 1)
        ),
        mipmapLevel: 0,
        withBytes: rasterizedGlyph.bytes,
        bytesPerRow: rasterizedGlyph.width
      )

      let entry = GlyphEntry(
        origin: rasterizedGlyph.origin,
        size: rasterizedGlyph.size,
        uvOrigin: .init(
          Float(nextX) / Float(texture.width),
          Float(nextY) / Float(texture.height)
        ),
        uvSize: .init(
          Float(rasterizedGlyph.width) / Float(texture.width),
          Float(rasterizedGlyph.height) / Float(texture.height)
        )
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
        bytesPerRow: texture.width
      )
    }
  }

  private static let metalRenderer = MetalRenderer()
  private static let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()

  private let gridID: Grid.ID
  private let store: Store
  private nonisolated let isolatedRenderContext = Mutex<RenderContext?>(nil)
  private nonisolated let metalGlyphAtlas = Mutex<MetalGlyphAtlas?>(nil)

  @MainActor
  public var isRendered: Bool {
    isolatedRenderContext.withLock { $0 != nil }
  }

  @MainActor
  public var renderContext: RenderContext {
    isolatedRenderContext.withLock { $0! }
  }

  @MainActor
  public func update(renderContext: RenderContext) {
    isolatedRenderContext.withLock { $0 = renderContext }
  }

  @MainActor
  public var grid: Grid? {
    guard isRendered else {
      return nil
    }
    return state.grids[gridID]
  }

  @MainActor
  private var upsideDownTransform: CGAffineTransform? {
    guard let grid else {
      return nil
    }
    return .init(scaleX: 1, y: -1)
      .translatedBy(x: 0, y: -Double(grid.rowsCount) * state.font.cellHeight)
  }

  override public init(layer: Any) {
    let gridLayer = layer as! GridLayer
    gridID = gridLayer.gridID
    store = gridLayer.store
    super.init(layer: layer)

    configureMetalLayer()
  }

  @MainActor
  init(
    store: Store,
    gridID: Grid.ID
  ) {
    self.store = store
    self.gridID = gridID
    super.init()

    configureMetalLayer()

    masksToBounds = true
    drawsAsynchronously = true
    needsDisplayOnBoundsChange = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @MainActor
  func updateDrawableSize() {
    let scale = max(contentsScale, 1)
    drawableSize = .init(
      width: ceil(bounds.width * scale),
      height: ceil(bounds.height * scale)
    )
  }

  private func configureMetalLayer() {
    guard let metalRenderer = Self.metalRenderer else {
      return
    }

    device = metalRenderer.device
    pixelFormat = .bgra8Unorm
    framebufferOnly = false
    colorspace = Self.colorSpace
    isOpaque = false
  }

  override public func display() {
    guard
      let metalRenderer = Self.metalRenderer,
      let snapshot = makeDrawSnapshot(),
      renderWithMetal(snapshot: snapshot, renderer: metalRenderer)
    else {
      super.display()
      return
    }
  }

  override public func draw(in ctx: CGContext) {
    guard let snapshot = makeDrawSnapshot() else {
      return
    }

    draw(
      snapshot: snapshot,
      in: ctx,
      clipRect: ctx.boundingBoxOfClipPath
    )
  }

  private func makeDrawSnapshot() -> DrawSnapshot? {
    isolatedRenderContext.withLock({ renderContext in
      guard
        let renderContext,
        let grid = renderContext.state.grids[gridID]
      else {
        return nil
      }

      let upsideDownTransform = CGAffineTransform(scaleX: 1, y: -1)
        .translatedBy(x: 0, y: -Double(grid.rowsCount) * renderContext.state.font.cellHeight)

      return DrawSnapshot(
        grid: grid,
        upsideDownTransform: upsideDownTransform,
        font: renderContext.state.font,
        appearance: renderContext.state.appearance,
        cursorBlinkingPhase: renderContext.state.cursorBlinkingPhase,
        isMouseUserInteractionEnabled: renderContext.state.isMouseUserInteractionEnabled
      )
    })
  }

  private func renderWithMetal(
    snapshot: DrawSnapshot,
    renderer: MetalRenderer
  ) -> Bool {
    guard !hasUnsupportedDecorations(snapshot: snapshot) else {
      return false
    }

    guard
      let drawable = nextDrawable(),
      let commandBuffer = renderer.commandQueue.makeCommandBuffer()
    else {
      return false
    }

    let scale = max(contentsScale, 1)
    guard let glyphAtlas = prepareGlyphAtlas(renderer: renderer, scale: scale) else {
      return false
    }

    let scene = buildMetalScene(
      snapshot: snapshot,
      renderer: renderer,
      glyphAtlas: glyphAtlas
    )

    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture
    renderPassDescriptor.colorAttachments[0].loadAction = .clear
    renderPassDescriptor.colorAttachments[0].storeAction = .store
    renderPassDescriptor.colorAttachments[0].clearColor = snapshot.appearance.defaultBackgroundColor.metalClearColor

    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
      return false
    }

    let uniforms = MetalUniforms(
      viewportSize: .init(Float(bounds.width), Float(bounds.height))
    )

    encodeQuadInstances(scene.backgroundQuads, uniforms: uniforms, renderer: renderer, encoder: renderEncoder)
    encodeGlyphInstances(scene.glyphInstances, uniforms: uniforms, renderer: renderer, atlasTexture: glyphAtlas.texture, encoder: renderEncoder)
    encodeQuadInstances(scene.cursorQuads, uniforms: uniforms, renderer: renderer, encoder: renderEncoder)
    encodeGlyphInstances(scene.cursorGlyphInstances, uniforms: uniforms, renderer: renderer, atlasTexture: glyphAtlas.texture, encoder: renderEncoder)
    renderEncoder.endEncoding()

    commandBuffer.present(drawable)
    commandBuffer.commit()

    return true
  }

  private func hasUnsupportedDecorations(snapshot: DrawSnapshot) -> Bool {
    let boundingRect = IntegerRectangle(
      frame: bounds.applying(snapshot.upsideDownTransform),
      cellSize: snapshot.font.cellSize
    )
    let visibleRowDrawRuns = snapshot.grid.drawRuns.visibleRowDrawRuns(
      boundingRect: boundingRect,
      font: snapshot.font,
      upsideDownTransform: snapshot.upsideDownTransform
    )

    for rowDrawRuns in visibleRowDrawRuns {
      for visibleDrawRun in rowDrawRuns.drawRuns {
        let decorations = snapshot.appearance.decorations(for: visibleDrawRun.drawRun.highlightID)
        if decorations != .init() {
          return true
        }
      }
    }

    return false
  }

  private func prepareGlyphAtlas(
    renderer: MetalRenderer,
    scale: CGFloat
  ) -> MetalGlyphAtlas? {
    metalGlyphAtlas.withLock { glyphAtlas in
      if let glyphAtlas, abs(glyphAtlas.scale - scale) < 0.001 {
        return glyphAtlas
      }

      glyphAtlas = MetalGlyphAtlas(renderer: renderer, scale: scale)
      return glyphAtlas
    }
  }

  private func buildMetalScene(
    snapshot: DrawSnapshot,
    renderer: MetalRenderer,
    glyphAtlas: MetalGlyphAtlas
  ) -> MetalScene {
    var scene = MetalScene()

    let boundingRect = IntegerRectangle(
      frame: bounds.applying(snapshot.upsideDownTransform),
      cellSize: snapshot.font.cellSize
    )
    let visibleRowDrawRuns = snapshot.grid.drawRuns.visibleRowDrawRuns(
      boundingRect: boundingRect,
      font: snapshot.font,
      upsideDownTransform: snapshot.upsideDownTransform
    )

    for rowDrawRuns in visibleRowDrawRuns {
      for visibleDrawRun in rowDrawRuns.drawRuns {
        let drawRun = visibleDrawRun.drawRun
        let rect = visibleDrawRun.rect
        scene.backgroundQuads.append(
          quadInstance(
            rect: rect,
            color: snapshot.appearance.backgroundColor(for: drawRun.highlightID).metal
          )
        )

        if let glyphRuns = drawRun.glyphRuns {
          appendGlyphInstances(
            glyphRuns,
            in: rect,
            color: snapshot.appearance.foregroundColor(for: drawRun.highlightID).metal,
            renderer: renderer,
            glyphAtlas: glyphAtlas,
            to: &scene.glyphInstances
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
        renderer: renderer,
        glyphAtlas: glyphAtlas,
        to: &scene
      )
    }

    return scene
  }

  private func appendGlyphInstances(
    _ glyphRuns: [GlyphRun],
    in rect: CGRect,
    color: SIMD4<Float>,
    renderer: MetalRenderer,
    glyphAtlas: MetalGlyphAtlas,
    clipRect: CGRect? = nil,
    to glyphInstances: inout [MetalGlyphInstance]
  ) {
    for glyphRun in glyphRuns {
      for index in glyphRun.glyphs.indices {
        guard let entry = glyphAtlas.entry(
          for: glyphRun.glyphs[index],
          font: glyphRun.appKitFont,
          renderer: renderer
        ) else {
          continue
        }

        let glyphRect = CGRect(
          x: rect.origin.x + glyphRun.positions[index].x + CGFloat(entry.origin.x),
          y: rect.origin.y + glyphRun.positions[index].y + CGFloat(entry.origin.y),
          width: CGFloat(entry.size.x),
          height: CGFloat(entry.size.y)
        )

        if let clipRect,
           let clippedInstance = clippedGlyphInstance(
             rect: glyphRect,
             uvOrigin: entry.uvOrigin,
             uvSize: entry.uvSize,
             color: color,
             clipRect: clipRect
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
              color: color
            )
          )
        }
      }
    }
  }

  private func appendCursorInstances(
    _ cursorDrawRun: CursorDrawRun,
    snapshot: DrawSnapshot,
    renderer: MetalRenderer,
    glyphAtlas: MetalGlyphAtlas,
    to scene: inout MetalScene
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
      quadInstance(rect: cursorRect, color: cursorBackgroundColor.metal)
    )

    if cursorDrawRun.shouldDrawParentText,
       let glyphRuns = cursorDrawRun.parentDrawRun.glyphRuns
    {
      let parentRectangle = IntegerRectangle(
        origin: .init(column: cursorDrawRun.parentOrigin.column, row: cursorDrawRun.parentOrigin.row),
        size: .init(columnsCount: cursorDrawRun.parentDrawRun.columnsCount, rowsCount: 1)
      )
      let parentRect = (parentRectangle * snapshot.font.cellSize)
        .applying(snapshot.upsideDownTransform)

      appendGlyphInstances(
        glyphRuns,
        in: parentRect,
        color: cursorForegroundColor.metal,
        renderer: renderer,
        glyphAtlas: glyphAtlas,
        clipRect: cursorRect,
        to: &scene.cursorGlyphInstances
      )
    }
  }

  private func quadInstance(
    rect: CGRect,
    color: SIMD4<Float>
  ) -> MetalQuadInstance {
    .init(
      origin: .init(Float(rect.origin.x), Float(rect.origin.y)),
      size: .init(Float(rect.width), Float(rect.height)),
      color: color
    )
  }

  private func clippedGlyphInstance(
    rect: CGRect,
    uvOrigin: SIMD2<Float>,
    uvSize: SIMD2<Float>,
    color: SIMD4<Float>,
    clipRect: CGRect
  ) -> MetalGlyphInstance? {
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
        uvOrigin.y + uvSize.y * top
      ),
      uvSize: .init(
        uvSize.x * max(0, 1 - left - right),
        uvSize.y * max(0, 1 - top - bottom)
      ),
      color: color
    )
  }

  private func encodeQuadInstances(
    _ instances: [MetalQuadInstance],
    uniforms: MetalUniforms,
    renderer: MetalRenderer,
    encoder: MTLRenderCommandEncoder
  ) {
    guard
      !instances.isEmpty,
      let buffer = instances.makeBuffer(device: renderer.device)
    else {
      return
    }

    var uniforms = uniforms
    encoder.setRenderPipelineState(renderer.quadPipelineState)
    encoder.setVertexBuffer(buffer, offset: 0, index: 0)
    encoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalUniforms>.stride, index: 1)
    encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: instances.count)
  }

  private func encodeGlyphInstances(
    _ instances: [MetalGlyphInstance],
    uniforms: MetalUniforms,
    renderer: MetalRenderer,
    atlasTexture: MTLTexture,
    encoder: MTLRenderCommandEncoder
  ) {
    guard
      !instances.isEmpty,
      let buffer = instances.makeBuffer(device: renderer.device)
    else {
      return
    }

    var uniforms = uniforms
    encoder.setRenderPipelineState(renderer.glyphPipelineState)
    encoder.setVertexBuffer(buffer, offset: 0, index: 0)
    encoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalUniforms>.stride, index: 1)
    encoder.setFragmentTexture(atlasTexture, index: 0)
    encoder.setFragmentSamplerState(renderer.glyphSamplerState, index: 0)
    encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: instances.count)
  }

  private func draw(
    snapshot: DrawSnapshot,
    in ctx: CGContext,
    clipRect: CGRect
  ) {
    ctx.saveGState()
    defer { ctx.restoreGState() }

    let boundingRect = IntegerRectangle(
      frame: clipRect.applying(snapshot.upsideDownTransform),
      cellSize: snapshot.font.cellSize
    )
    let visibleRowDrawRuns = snapshot.grid.drawRuns.visibleRowDrawRuns(
      boundingRect: boundingRect,
      font: snapshot.font,
      upsideDownTransform: snapshot.upsideDownTransform
    )

    ctx.setAllowsAntialiasing(false)
    ctx.setAllowsFontSmoothing(false)
    ctx.setShouldAntialias(false)
    ctx.setShouldSmoothFonts(false)
    for rowDrawRuns in visibleRowDrawRuns {
      for visibleDrawRun in rowDrawRuns.drawRuns {
        visibleDrawRun.drawRun.drawBackground(
          to: ctx,
          at: visibleDrawRun.rect.origin,
          font: snapshot.font,
          appearance: snapshot.appearance
        )
      }
    }

    ctx.setAllowsAntialiasing(true)
    ctx.setAllowsFontSmoothing(true)
    ctx.setShouldAntialias(true)
    ctx.setShouldSmoothFonts(true)
    for rowDrawRuns in visibleRowDrawRuns {
      for visibleDrawRun in rowDrawRuns.drawRuns {
        visibleDrawRun.drawRun.drawForeground(
          to: ctx,
          at: visibleDrawRun.rect,
          font: snapshot.font,
          appearance: snapshot.appearance
        )
      }
    }

    if
      snapshot.cursorBlinkingPhase,
      snapshot.isMouseUserInteractionEnabled,
      let cursorDrawRun = snapshot.grid.drawRuns.cursorDrawRun,
      boundingRect.contains(cursorDrawRun.origin)
    {
      cursorDrawRun.draw(
        to: ctx,
        font: snapshot.font,
        appearance: snapshot.appearance,
        upsideDownTransform: snapshot.upsideDownTransform
      )
    }
  }

  @MainActor
  public func render() {
    for dirtyRect in calculateDirtyRects() {
      let clippedDirtyRect = dirtyRect.intersection(bounds)
      guard !clippedDirtyRect.isNull, !clippedDirtyRect.isEmpty else {
        continue
      }
      setNeedsDisplay(clippedDirtyRect)
    }
  }

  @MainActor
  private func calculateDirtyRects() -> [CGRect] {
    guard isRendered, let grid, let upsideDownTransform else {
      return []
    }

    if updates.isFontUpdated || updates.isAppearanceUpdated {
      return [bounds]
    }

    var dirtyRects: [CGRect] = []

    if let gridUpdate = updates.gridUpdates[gridID] {
      switch gridUpdate {
      case let .dirtyRectangles(value):
        for rectangle in value {
          dirtyRects.append(
            (rectangle * state.font.cellSize)
              .insetBy(dx: -state.font.cellSize.width, dy: -state.font.cellSize.height * 0.5)
              .applying(upsideDownTransform)
          )
        }

      case .needsDisplay:
        return [bounds]
      }
    }

    if
      let cursorDrawRun = grid.drawRuns.cursorDrawRun,
      updates.isCursorBlinkingPhaseUpdated || updates.isMouseUserInteractionEnabledUpdated
    {
      dirtyRects.append(
        (cursorDrawRun.rectangle * state.font.cellSize)
          .applying(upsideDownTransform)
      )
    }

    return dirtyRects
  }
}

extension CGContext: @unchecked @retroactive Sendable { }

private extension Color {
  var metal: SIMD4<Float> {
    let color = appKit.usingColorSpace(.deviceRGB) ?? appKit
    return .init(
      Float(color.redComponent),
      Float(color.greenComponent),
      Float(color.blueComponent),
      Float(color.alphaComponent)
    )
  }

  var metalClearColor: MTLClearColor {
    let metal = metal
    return .init(
      red: Double(metal.x),
      green: Double(metal.y),
      blue: Double(metal.z),
      alpha: Double(metal.w)
    )
  }
}

private extension Array {
  func makeBuffer(device: MTLDevice) -> MTLBuffer? {
    withUnsafeBytes { bytes in
      guard let baseAddress = bytes.baseAddress, !bytes.isEmpty else {
        return nil
      }
      return device.makeBuffer(bytes: baseAddress, length: bytes.count)
    }
  }
}
