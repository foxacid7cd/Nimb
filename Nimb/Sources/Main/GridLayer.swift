// SPDX-License-Identifier: MIT

import Algorithms
import AppKit
import Collections
import CustomDump
import Metal
import QuartzCore
import Queue
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

public class GridLayer: CAMetalLayer, @unchecked Sendable {
  private struct MetalUniforms {
    var viewportSize: SIMD2<Float>
  }

  private final class MetalBufferCache: @unchecked Sendable {
    enum Kind {
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
    private var entries: [Kind: Entry] = [:]

    init(device: MTLDevice) {
      self.device = device
    }

    func buffer<T>(for values: [T], kind: Kind) -> MTLBuffer? {
      let length = MemoryLayout<T>.stride * values.count
      guard length > 0 else {
        return nil
      }

      if entries[kind]?.capacity ?? 0 < length {
        var capacity = max(4 * 1024, MemoryLayout<T>.stride)
        while capacity < length {
          capacity *= 2
        }

        guard let buffer = device.makeBuffer(length: capacity, options: .storageModeShared) else {
          return nil
        }
        entries[kind] = Entry(buffer: buffer, capacity: capacity)
      }

      guard let entry = entries[kind] else {
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

  private let gridID: Grid.ID
  private let store: Store
  private nonisolated let isolatedRenderInput = Mutex<GridRenderInput?>(nil)
  private var metalBufferCache: MetalBufferCache? = nil

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
    guard
      let metalRenderer = Self.metalRenderer,
      let renderInput = currentRenderInput(),
      renderWithMetal(renderInput: renderInput, renderer: metalRenderer)
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
      clipRect: ctx.boundingBoxOfClipPath,
    )
  }

  nonisolated func update(renderInput: GridRenderInput?) {
    isolatedRenderInput.withLock { $0 = renderInput }
  }

  public nonisolated func render() {
    guard let renderInput = isolatedRenderInput.withLock({ $0 }) else {
      return
    }

    for dirtyRect in calculateDirtyRects(renderInput: renderInput) {
      let clippedDirtyRect = dirtyRect.intersection(bounds)
      guard !clippedDirtyRect.isNull, !clippedDirtyRect.isEmpty else {
        continue
      }
      setNeedsDisplay(clippedDirtyRect)
    }
  }

  func updateDrawableSize() {
    let scale = max(contentsScale, 1)
    drawableSize = .init(
      width: ceil(bounds.width * scale),
      height: ceil(bounds.height * scale),
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

    let uniforms = MetalUniforms(
      viewportSize: .init(Float(bounds.width), Float(bounds.height)),
    )
    let bufferCache = prepareBufferCache(renderer: renderer)

    encodeQuadInstances(metalFrame.scene.backgroundQuads, kind: .backgroundQuads, uniforms: uniforms, renderer: renderer, bufferCache: bufferCache, encoder: renderEncoder)
    encodeQuadInstances(metalFrame.scene.decorationQuads, kind: .decorationQuads, uniforms: uniforms, renderer: renderer, bufferCache: bufferCache, encoder: renderEncoder)
    encodeGlyphInstances(metalFrame.scene.glyphInstances, kind: .glyphs, uniforms: uniforms, renderer: renderer, bufferCache: bufferCache, atlasTexture: metalFrame.atlasTexture, encoder: renderEncoder)
    encodeQuadInstances(metalFrame.scene.cursorQuads, kind: .cursorQuads, uniforms: uniforms, renderer: renderer, bufferCache: bufferCache, encoder: renderEncoder)
    encodeGlyphInstances(metalFrame.scene.cursorGlyphInstances, kind: .cursorGlyphs, uniforms: uniforms, renderer: renderer, bufferCache: bufferCache, atlasTexture: metalFrame.atlasTexture, encoder: renderEncoder)
    renderEncoder.endEncoding()

    commandBuffer.present(drawable)
    commandBuffer.commit()

    return true
  }

  private func prepareBufferCache(renderer: GridMetalRenderer) -> MetalBufferCache {
    if let metalBufferCache {
      return metalBufferCache
    }

    let bufferCache = MetalBufferCache(device: renderer.device)
    metalBufferCache = bufferCache
    return bufferCache
  }

  private func encodeQuadInstances(
        _ instances: [GridMetalQuadInstance],
    kind: MetalBufferCache.Kind,
    uniforms: MetalUniforms,
        renderer: GridMetalRenderer,
    bufferCache: MetalBufferCache,
    encoder: MTLRenderCommandEncoder,
  ) {
    guard
      !instances.isEmpty,
      let buffer = bufferCache.buffer(for: instances, kind: kind)
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
    _ instances: [GridMetalGlyphInstance],
    kind: MetalBufferCache.Kind,
    uniforms: MetalUniforms,
    renderer: GridMetalRenderer,
    bufferCache: MetalBufferCache,
    atlasTexture: MTLTexture,
    encoder: MTLRenderCommandEncoder,
  ) {
    guard
      !instances.isEmpty,
      let buffer = bufferCache.buffer(for: instances, kind: kind)
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
    snapshot: GridDrawSnapshot,
    in ctx: CGContext,
    clipRect: CGRect,
  ) {
    ctx.saveGState()
    defer { ctx.restoreGState() }

    let boundingRect = IntegerRectangle(
      frame: clipRect.applying(snapshot.upsideDownTransform),
      cellSize: snapshot.font.cellSize,
    )
    let visibleRowDrawRuns = snapshot.grid.drawRuns.visibleRowDrawRuns(
      boundingRect: boundingRect,
      font: snapshot.font,
      upsideDownTransform: snapshot.upsideDownTransform,
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
          appearance: snapshot.appearance,
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
          appearance: snapshot.appearance,
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
        upsideDownTransform: snapshot.upsideDownTransform,
      )
    }
  }

  private func calculateDirtyRects(renderInput: GridRenderInput) -> [CGRect] {
    let snapshot = renderInput.snapshot
    let grid = snapshot.grid
    let upsideDownTransform = CGAffineTransform(scaleX: 1, y: -1)
      .translatedBy(x: 0, y: -Double(grid.rowsCount) * snapshot.font.cellHeight)

    if renderInput.updates.isFontUpdated || renderInput.updates.isAppearanceUpdated {
      return [bounds]
    }

    var dirtyRects: [CGRect] = []

    if let gridUpdate = renderInput.updates.gridUpdates[gridID] {
      switch gridUpdate {
      case let .dirtyRectangles(value):
        for rectangle in value {
          dirtyRects.append(
            (rectangle * snapshot.font.cellSize)
              .insetBy(
                dx: -snapshot.font.cellSize.width,
                dy: -snapshot.font.cellSize.height * 0.5,
              )
              .applying(upsideDownTransform),
          )
        }

      case .needsDisplay:
        return [bounds]
      }
    }

    if
      let cursorDrawRun = grid.drawRuns.cursorDrawRun,
      renderInput.updates.isCursorBlinkingPhaseUpdated || renderInput.updates.isMouseUserInteractionEnabledUpdated
    {
      dirtyRects.append(
        (cursorDrawRun.rectangle * snapshot.font.cellSize)
          .applying(upsideDownTransform),
      )
    }

    return dirtyRects
  }
}

extension CGContext: @unchecked @retroactive Sendable { }
