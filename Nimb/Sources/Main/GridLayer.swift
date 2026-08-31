// SPDX-License-Identifier: MIT

import Algorithms
import AppKit
import Collections
import CustomDump
import Metal
import NimbCore
import NimbState
import QuartzCore
import Synchronization

struct GridDrawSnapshot: Sendable {
  let grid: Grid
  let upsideDownTransform: CGAffineTransform
  let font: Font
  let appearance: Appearance
  let cursorBlinkingPhase: Bool
  let isMouseUserInteractionEnabled: Bool
}

struct GridRenderInput: Sendable {
  let snapshot: GridDrawSnapshot
  let updates: State.Updates
  let metalFrame: GridPreparedMetalFrame?
}

/// Stays off the main actor: CALayer's initialisers and draw(in:) are
/// nonisolated in the SDK, so an isolated subclass cannot override them.
public nonisolated class GridLayer: CAMetalLayer {
  private struct MetalUniforms {
    var viewportSize: SIMD2<Float>
  }

  /// One buffer per (kind, in-flight frame), so a frame cannot rewrite instance
  /// data the GPU is still reading. Depth matches the drawable pool.
  private final class MetalBufferCache {
    enum Kind: Int, CaseIterable {
      case backgroundQuads
      case decorationQuads
      case glyphs
      case cursorQuads
      case cursorGlyphs
      case rowOffsets
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
  /// Also the depth of the instance buffer ring; the two have to agree, since
  /// the drawable pool bounds how many frames the GPU can be reading.
  private static let maximumFramesInFlight = 3

  /// Called the first time this layer has a frame to draw, so the view above can
  /// stop hiding itself. Fired on handover, not on present, to save a hop.
  nonisolated(unsafe) var onFirstFrameReady: (@MainActor () -> Void)? = nil

  private let gridID: Grid.ID
  private let store: Store
  private nonisolated let isolatedRenderInput = Mutex<GridRenderInput?>(nil)
  private var metalBufferCache: MetalBufferCache? = nil
  private let hasSignalledFirstFrame = Mutex(false)

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
    gridID: Grid.ID,
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

  override public func display() {
    let didRenderWithMetal = measuringRenderStage("display", .display) {
      guard
        let metalRenderer = Self.metalRenderer,
        let renderInput = currentRenderInput()
      else {
        return false
      }
      return renderWithMetal(renderInput: renderInput, renderer: metalRenderer)
    }

    if !didRenderWithMetal {
      super.display()
    }
  }

  override public func draw(in ctx: CGContext) {
    guard let snapshot = makeDrawSnapshot() else {
      return
    }

    GridCoreGraphicsRenderer.draw(
      snapshot: snapshot,
      in: ctx,
      clipRect: ctx.boundingBoxOfClipPath,
    )
  }

  public nonisolated func render() {
    let hasFrame = isolatedRenderInput.withLock { renderInput -> Bool? in
      guard let renderInput else {
        return nil
      }
      return renderInput.metalFrame != nil
    }
    guard let hasFrame else {
      return
    }

    // Whole layer, not the dirty rectangles: display() re-encodes the entire
    // scene whatever is marked. Unconditional, since GridView already gated it.
    setNeedsDisplay()

    if hasFrame {
      signalFirstFrameIfNeeded()
    }
  }

  nonisolated func update(renderInput: GridRenderInput?) {
    isolatedRenderInput.withLock { $0 = renderInput }
  }

  func updateDrawableSize() {
    let scale = max(contentsScale, 1)
    drawableSize = .init(
      width: ceil(bounds.width * scale),
      height: ceil(bounds.height * scale),
    )
  }

  /// Painted behind the drawable, so the only moments it shows -- before the
  /// first frame, and gaps during a resize -- are not transparent.
  func setBackground(_ color: Color) {
    backgroundColor = color.appKit.cgColor
  }

  /// Both call sites are already on the main actor, which is what makes
  /// assuming it here sound.
  private nonisolated func signalFirstFrameIfNeeded() {
    let shouldSignal = hasSignalledFirstFrame.withLock { signalled -> Bool in
      guard !signalled else {
        return false
      }
      signalled = true
      return true
    }
    guard shouldSignal, let onFirstFrameReady else {
      return
    }
    MainActor.assumeIsolated { onFirstFrameReady() }
  }

  private func configureMetalLayer() {
    guard let metalRenderer = Self.metalRenderer else {
      return
    }

    device = metalRenderer.device
    pixelFormat = .bgra8Unorm
    // Stated rather than left to the default, because the buffer ring below is
    // sized to match it.
    maximumDrawableCount = Self.maximumFramesInFlight
    // The drawable is only ever a render target, so it can stay
    // framebuffer-only and keep lossless compression.
    framebufferOnly = true
    colorspace = Self.colorSpace
    isOpaque = false
  }

  private func makeDrawSnapshot() -> GridDrawSnapshot? {
    isolatedRenderInput.withLock { $0?.snapshot }
  }

  private func currentRenderInput() -> GridRenderInput? {
    isolatedRenderInput.withLock { $0 }
  }

  private func renderWithMetal(
    renderInput: GridRenderInput,
    renderer: GridMetalRenderer,
  )
  -> Bool {
    guard
      let metalFrame = renderInput.metalFrame,
      let drawable = nextDrawable(),
      let commandBuffer = renderer.commandQueue.makeCommandBuffer()
    else {
      return false
    }

    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture
    renderPassDescriptor.colorAttachments[0].loadAction = .clear
    renderPassDescriptor.colorAttachments[0].storeAction = .store
    renderPassDescriptor.colorAttachments[0].clearColor = metalFrame.clearColor

    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
      return false
    }

    // The drawable rounds up to whole pixels, so its size in points is what
    // maps one point to exactly `scale` pixels. Taking bounds instead stretches
    // the scene by the rounded-up fraction, and every glyph quad the scene
    // builder snapped to the pixel grid lands off it, blurred by the sampler.
    let scale = max(contentsScale, 1)
    let uniforms = MetalUniforms(
      viewportSize: .init(
        Float(drawableSize.width / scale),
        Float(drawableSize.height / scale),
      ),
    )
    let bufferCache = prepareBufferCache(renderer: renderer)
    bufferCache.advance()

    // One float per row slot; the shader adds it to every instance carrying
    // that slot, so a scrolled row keeps the instances it already had.
    let rowOffsetsBuffer = bufferCache.buffer(
      for: metalFrame.scene.rowOffsets,
      kind: .rowOffsets,
    )

    encodeQuadInstances(
      metalFrame.scene.backgroundQuads,
      kind: .backgroundQuads,
      uniforms: uniforms,
      renderer: renderer,
      bufferCache: bufferCache,
      rowOffsetsBuffer: rowOffsetsBuffer,
      encoder: renderEncoder,
    )
    encodeQuadInstances(
      metalFrame.scene.decorationQuads,
      kind: .decorationQuads,
      uniforms: uniforms,
      renderer: renderer,
      bufferCache: bufferCache,
      rowOffsetsBuffer: rowOffsetsBuffer,
      encoder: renderEncoder,
    )
    encodeGlyphInstances(
      metalFrame.scene.glyphInstances,
      kind: .glyphs,
      uniforms: uniforms,
      renderer: renderer,
      bufferCache: bufferCache,
      rowOffsetsBuffer: rowOffsetsBuffer,
      atlasTexture: metalFrame.atlasTexture,
      encoder: renderEncoder,
    )
    encodeQuadInstances(metalFrame.scene.cursorQuads, kind: .cursorQuads, uniforms: uniforms, renderer: renderer, bufferCache: bufferCache, rowOffsetsBuffer: rowOffsetsBuffer, encoder: renderEncoder)
    encodeGlyphInstances(
      metalFrame.scene.cursorGlyphInstances,
      kind: .cursorGlyphs,
      uniforms: uniforms,
      renderer: renderer,
      bufferCache: bufferCache,
      rowOffsetsBuffer: rowOffsetsBuffer,
      atlasTexture: metalFrame.atlasTexture,
      encoder: renderEncoder,
    )
    renderEncoder.endEncoding()

    commandBuffer.present(drawable)
    commandBuffer.commit()

    return true
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

  private func encodeQuadInstances(
    _ instances: [GridMetalQuadInstance],
    kind: MetalBufferCache.Kind,
    uniforms: MetalUniforms,
    renderer: GridMetalRenderer,
    bufferCache: MetalBufferCache,
    rowOffsetsBuffer: MTLBuffer?,
    encoder: MTLRenderCommandEncoder,
  ) {
    guard
      !instances.isEmpty,
      let rowOffsetsBuffer,
      let buffer = bufferCache.buffer(for: instances, kind: kind)
    else {
      return
    }

    var uniforms = uniforms
    encoder.setRenderPipelineState(renderer.quadPipelineState)
    encoder.setVertexBuffer(buffer, offset: 0, index: 0)
    encoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalUniforms>.stride, index: 1)
    encoder.setVertexBuffer(rowOffsetsBuffer, offset: 0, index: 2)
    encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: instances.count)
  }

  private func encodeGlyphInstances(
    _ instances: [GridMetalGlyphInstance],
    kind: MetalBufferCache.Kind,
    uniforms: MetalUniforms,
    renderer: GridMetalRenderer,
    bufferCache: MetalBufferCache,
    rowOffsetsBuffer: MTLBuffer?,
    atlasTexture: MTLTexture,
    encoder: MTLRenderCommandEncoder,
  ) {
    guard
      !instances.isEmpty,
      let rowOffsetsBuffer,
      let buffer = bufferCache.buffer(for: instances, kind: kind)
    else {
      return
    }

    var uniforms = uniforms
    encoder.setRenderPipelineState(renderer.glyphPipelineState)
    encoder.setVertexBuffer(buffer, offset: 0, index: 0)
    encoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalUniforms>.stride, index: 1)
    encoder.setVertexBuffer(rowOffsetsBuffer, offset: 0, index: 2)
    encoder.setFragmentTexture(atlasTexture, index: 0)
    encoder.setFragmentSamplerState(renderer.glyphSamplerState, index: 0)
    encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: instances.count)
  }
}
