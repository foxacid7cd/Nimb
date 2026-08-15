// SPDX-License-Identifier: MIT

import AppKit
import Metal
import NimbCore
import NimbState
import QuartzCore
import Synchronization

/// The one Metal surface every grid paints into.
///
/// There used to be a CAMetalLayer per grid, so a window with six splits meant
/// six drawable chains, six command buffers and six presents a frame, and six
/// surfaces for the compositor to blend. Grids are scissored regions of a
/// single drawable instead; the per-grid clipping that masksToBounds used to
/// provide is now a scissor rect per draw.
///
/// Stays off the main actor even though the rest of the app target defaults to
/// it: CALayer's initialisers and draw(in:) are nonisolated in the SDK, so an
/// isolated subclass cannot override them.
public nonisolated class GridsMetalLayer: CAMetalLayer {
  private struct MetalUniforms {
    var viewportSize: SIMD2<Float>
    var gridOrigin: SIMD2<Float>
  }

  /// One buffer per (kind, in-flight frame).
  ///
  /// A single buffer per kind, refilled at the top of every display(), let the
  /// GPU still be reading one for a frame that had been presented but not yet
  /// finished. Cycling matches the number of drawables the layer is allowed to
  /// have outstanding, which is what bounds how many frames can be reading at
  /// once -- nextDrawable blocks past that, so the ring can never wrap onto a
  /// buffer that is still live.
  private final class MetalBufferCache {
    enum Kind: Int, CaseIterable {
      case backgroundQuads
      case decorationQuads
      case glyphs
      case cursorQuads
      case cursorGlyphs
    }

    private struct Entry {
      let buffer: MTLBuffer
      let capacity: Int
    }

    private let device: MTLDevice
    private let depth: Int
    private var frameIndex = 0
    /// Indexed by `kind.rawValue * depth + frameIndex`.
    private var entries: [Entry?]

    init(device: MTLDevice, depth: Int) {
      self.device = device
      self.depth = depth
      entries = .init(repeating: nil, count: Kind.allCases.count * depth)
    }

    /// Moves to the next set of buffers. Call once per frame, before writing
    /// anything.
    func advance() {
      frameIndex = (frameIndex + 1) % depth
    }

    func buffer<T>(for values: [T], kind: Kind) -> MTLBuffer? {
      let length = MemoryLayout<T>.stride * values.count
      guard length > 0 else {
        return nil
      }

      let slot = kind.rawValue * depth + frameIndex
      if entries[slot]?.capacity ?? 0 < length {
        var capacity = max(4 * 1024, MemoryLayout<T>.stride)
        while capacity < length {
          capacity *= 2
        }

        guard let buffer = device.makeBuffer(length: capacity, options: .storageModeShared) else {
          return nil
        }
        entries[slot] = Entry(buffer: buffer, capacity: capacity)
      }

      guard let entry = entries[slot] else {
        return nil
      }

      values.withUnsafeBytes { bytes in
        guard let baseAddress = bytes.baseAddress else {
          return
        }
        memcpy(entry.buffer.contents(), baseAddress, length)
      }

      return entry.buffer
    }
  }

  private static let metalRenderer = GridMetalRenderer.shared
  private static let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
  /// Also the depth of the instance buffer ring, and the two have to agree:
  /// the drawable pool is what bounds the number of frames the GPU can be
  /// reading instance data for.
  private static let maximumFramesInFlight = 3

  private nonisolated let isolatedFrame = Mutex<GridsPreparedMetalFrame?>(nil)
  private var metalBufferCache: MetalBufferCache? = nil

  /// Deliberately does not configure anything.
  ///
  /// CoreAnimation calls this to make presentation copies, and touching
  /// pixelFormat or colorspace on one segfaults inside QuartzCore -- the copy
  /// is not a layer that owns a drawable chain. Nothing renders through a
  /// presentation layer here anyway. Suppressing implicit animations (see
  /// GridsView) stops most copies being made at all; this makes the rest safe.
  override public init(layer: Any) {
    super.init(layer: layer)
  }

  override public init() {
    super.init()

    configureMetalLayer()

    masksToBounds = true
    needsDisplayOnBoundsChange = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func display() {
    measuringRenderStage("display", .display) {
      guard
        let metalRenderer = Self.metalRenderer,
        let frame = isolatedFrame.withLock({ $0 })
      else {
        return
      }
      render(frame: frame, renderer: metalRenderer)
    }
  }

  nonisolated func update(frame: GridsPreparedMetalFrame?) {
    isolatedFrame.withLock { $0 = frame }
  }

  /// Every frame repaints the whole surface: the pass clears and every visible
  /// grid is re-encoded, so there are no dirty rects to accumulate the way the
  /// CoreGraphics layer needs.
  nonisolated func render() {
    setNeedsDisplay()
  }

  func updateDrawableSize() {
    let scale = max(contentsScale, 1)
    let width = ceil(bounds.width * scale)
    let height = ceil(bounds.height * scale)
    // CAMetalLayer rejects a zero drawable size with a console error, and the
    // bounds are zero until the first layout pass.
    guard width > 0, height > 0 else {
      return
    }
    drawableSize = .init(width: width, height: height)
  }

  private func configureMetalLayer() {
    guard let metalRenderer = Self.metalRenderer else {
      return
    }

    device = metalRenderer.device
    pixelFormat = .bgra8Unorm
    // Stated rather than left to the default, because the buffer ring is sized
    // to match it.
    maximumDrawableCount = Self.maximumFramesInFlight
    // The drawable is only ever a render target -- nothing samples, blits or
    // reads it back -- so it can stay framebuffer-only and keep lossless
    // compression.
    framebufferOnly = true
    colorspace = Self.colorSpace
    isOpaque = false
  }

  private func render(
    frame: GridsPreparedMetalFrame,
    renderer: GridMetalRenderer,
  ) {
    guard
      let drawable = nextDrawable(),
      let commandBuffer = renderer.commandQueue.makeCommandBuffer()
    else {
      return
    }

    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture
    renderPassDescriptor.colorAttachments[0].loadAction = .clear
    renderPassDescriptor.colorAttachments[0].storeAction = .store
    renderPassDescriptor.colorAttachments[0].clearColor = frame.clearColor

    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
      return
    }

    let bufferCache = prepareBufferCache(renderer: renderer)
    bufferCache.advance()

    let viewportSize = SIMD2<Float>(Float(bounds.width), Float(bounds.height))
    let backgroundQuadsBuffer = bufferCache.buffer(for: frame.scene.backgroundQuads, kind: .backgroundQuads)
    let decorationQuadsBuffer = bufferCache.buffer(for: frame.scene.decorationQuads, kind: .decorationQuads)
    let glyphsBuffer = bufferCache.buffer(for: frame.scene.glyphInstances, kind: .glyphs)
    let cursorQuadsBuffer = bufferCache.buffer(for: frame.scene.cursorQuads, kind: .cursorQuads)
    let cursorGlyphsBuffer = bufferCache.buffer(for: frame.scene.cursorGlyphInstances, kind: .cursorGlyphs)

    // Grid by grid rather than kind by kind. Drawing all backgrounds first
    // would put a grid behind another one's glyphs on top of the front grid's
    // background.
    for draw in frame.draws {
      renderEncoder.setScissorRect(draw.scissorRect)

      var uniforms = MetalUniforms(viewportSize: viewportSize, gridOrigin: draw.origin)

      encodeQuads(
        buffer: backgroundQuadsBuffer,
        range: draw.backgroundQuads,
        uniforms: &uniforms,
        renderer: renderer,
        encoder: renderEncoder,
      )
      encodeQuads(
        buffer: decorationQuadsBuffer,
        range: draw.decorationQuads,
        uniforms: &uniforms,
        renderer: renderer,
        encoder: renderEncoder,
      )
      encodeGlyphs(
        buffer: glyphsBuffer,
        range: draw.glyphInstances,
        uniforms: &uniforms,
        renderer: renderer,
        atlasTexture: frame.atlasTexture,
        encoder: renderEncoder,
      )
      encodeQuads(
        buffer: cursorQuadsBuffer,
        range: draw.cursorQuads,
        uniforms: &uniforms,
        renderer: renderer,
        encoder: renderEncoder,
      )
      encodeGlyphs(
        buffer: cursorGlyphsBuffer,
        range: draw.cursorGlyphInstances,
        uniforms: &uniforms,
        renderer: renderer,
        atlasTexture: frame.atlasTexture,
        encoder: renderEncoder,
      )
    }

    renderEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }

  private func prepareBufferCache(renderer: GridMetalRenderer) -> MetalBufferCache {
    if let metalBufferCache {
      return metalBufferCache
    }

    let bufferCache = MetalBufferCache(
      device: renderer.device,
      depth: Self.maximumFramesInFlight,
    )
    metalBufferCache = bufferCache
    return bufferCache
  }

  private func encodeQuads(
    buffer: MTLBuffer?,
    range: Range<Int>,
    uniforms: inout MetalUniforms,
    renderer: GridMetalRenderer,
    encoder: MTLRenderCommandEncoder,
  ) {
    guard let buffer, !range.isEmpty else {
      return
    }

    encoder.setRenderPipelineState(renderer.quadPipelineState)
    // Rebased rather than drawn with a base instance, so the shader can keep
    // indexing from zero. Device address space allows any four byte aligned
    // offset, which a stride multiple always is.
    encoder.setVertexBuffer(
      buffer,
      offset: MemoryLayout<GridMetalQuadInstance>.stride * range.lowerBound,
      index: 0,
    )
    encoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalUniforms>.stride, index: 1)
    encoder.drawPrimitives(
      type: .triangleStrip,
      vertexStart: 0,
      vertexCount: 4,
      instanceCount: range.count,
    )
  }

  private func encodeGlyphs(
    buffer: MTLBuffer?,
    range: Range<Int>,
    uniforms: inout MetalUniforms,
    renderer: GridMetalRenderer,
    atlasTexture: MTLTexture,
    encoder: MTLRenderCommandEncoder,
  ) {
    guard let buffer, !range.isEmpty else {
      return
    }

    encoder.setRenderPipelineState(renderer.glyphPipelineState)
    encoder.setVertexBuffer(
      buffer,
      offset: MemoryLayout<GridMetalGlyphInstance>.stride * range.lowerBound,
      index: 0,
    )
    encoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalUniforms>.stride, index: 1)
    encoder.setFragmentTexture(atlasTexture, index: 0)
    encoder.setFragmentSamplerState(renderer.glyphSamplerState, index: 0)
    encoder.drawPrimitives(
      type: .triangleStrip,
      vertexStart: 0,
      vertexCount: 4,
      instanceCount: range.count,
    )
  }
}
