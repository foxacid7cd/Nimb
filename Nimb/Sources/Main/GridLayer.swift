// SPDX-License-Identifier: MIT

import Algorithms
import Collections
import ConcurrencyExtras
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

  private final class MetalRenderer: @unchecked Sendable {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue

    init?(device: MTLDevice? = MTLCreateSystemDefaultDevice()) {
      guard
        let device,
        let commandQueue = device.makeCommandQueue()
      else {
        return nil
      }

      self.device = device
      self.commandQueue = commandQueue
    }
  }

  private final class MetalBackingStore: @unchecked Sendable {
    let width: Int
    let height: Int
    let scale: CGFloat
    let bytesPerRow: Int
    let data: UnsafeMutableRawPointer
    let context: CGContext
    let texture: MTLTexture

    init?(
      renderer: MetalRenderer,
      width: Int,
      height: Int,
      scale: CGFloat,
      colorSpace: CGColorSpace
    ) {
      guard width > 0, height > 0 else {
        return nil
      }

      let bytesPerRow = width * 4
      let data = UnsafeMutableRawPointer.allocate(
        byteCount: height * bytesPerRow,
        alignment: MemoryLayout<UInt32>.alignment
      )
      data.initializeMemory(as: UInt8.self, repeating: 0, count: height * bytesPerRow)

      guard
        let context = CGContext(
          data: data,
          width: width,
          height: height,
          bitsPerComponent: 8,
          bytesPerRow: bytesPerRow,
          space: colorSpace,
          bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
            | CGBitmapInfo.byteOrder32Little.rawValue
        )
      else {
        data.deallocate()
        return nil
      }

      let descriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .bgra8Unorm,
        width: width,
        height: height,
        mipmapped: false
      )
      descriptor.usage = [.shaderRead, .shaderWrite]
      descriptor.storageMode = .managed

      guard let texture = renderer.device.makeTexture(descriptor: descriptor) else {
        data.deallocate()
        return nil
      }

      self.width = width
      self.height = height
      self.scale = scale
      self.bytesPerRow = bytesPerRow
      self.data = data
      self.context = context
      self.texture = texture
    }

    deinit {
      data.deallocate()
    }
  }

  private static let metalRenderer = MetalRenderer()
  private static let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()

  private let gridID: Grid.ID
  private let store: Store
  private nonisolated let isolatedRenderContext = Mutex<RenderContext?>(nil)
  private nonisolated let pendingDirtyRects = Mutex<[CGRect]>([])
  private nonisolated let metalBackingStore = Mutex<MetalBackingStore?>(nil)

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
    pendingDirtyRects.withLock { $0 = [bounds] }
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
    let scale = max(contentsScale, 1)
    let pixelWidth = Int(drawableSize.width)
    let pixelHeight = Int(drawableSize.height)
    guard pixelWidth > 0, pixelHeight > 0 else {
      return true
    }

    let dirtyRects = pendingDirtyRects.withLock { dirtyRects in
      let result = dirtyRects.isEmpty ? [bounds] : dirtyRects
      dirtyRects.removeAll(keepingCapacity: true)
      return result
    }

    guard let backingStore = prepareBackingStore(
      renderer: renderer,
      width: pixelWidth,
      height: pixelHeight,
      scale: scale
    ) else {
      return false
    }

    redraw(dirtyRects: dirtyRects, snapshot: snapshot, into: backingStore)

    guard
      let drawable = nextDrawable(),
      let commandBuffer = renderer.commandQueue.makeCommandBuffer()
    else {
      return false
    }

    if backingStore.texture.storageMode == .managed {
      let blitEncoder = commandBuffer.makeBlitCommandEncoder()
      blitEncoder?.synchronize(resource: backingStore.texture)
      blitEncoder?.endEncoding()
    }

    let blitEncoder = commandBuffer.makeBlitCommandEncoder()
    let copyWidth = min(backingStore.width, drawable.texture.width)
    let copyHeight = min(backingStore.height, drawable.texture.height)
    blitEncoder?.copy(
      from: backingStore.texture,
      sourceSlice: 0,
      sourceLevel: 0,
      sourceOrigin: .init(x: 0, y: 0, z: 0),
      sourceSize: .init(width: copyWidth, height: copyHeight, depth: 1),
      to: drawable.texture,
      destinationSlice: 0,
      destinationLevel: 0,
      destinationOrigin: .init(x: 0, y: 0, z: 0)
    )
    blitEncoder?.endEncoding()

    commandBuffer.present(drawable)
    commandBuffer.commit()

    return true
  }

  private func prepareBackingStore(
    renderer: MetalRenderer,
    width: Int,
    height: Int,
    scale: CGFloat
  ) -> MetalBackingStore? {
    metalBackingStore.withLock { backingStore in
      if let backingStore,
         backingStore.width == width,
         backingStore.height == height,
         backingStore.scale == scale {
        return backingStore
      }

      backingStore = MetalBackingStore(
        renderer: renderer,
        width: width,
        height: height,
        scale: scale,
        colorSpace: Self.colorSpace
      )
      return backingStore
    }
  }

  private func redraw(
    dirtyRects: [CGRect],
    snapshot: DrawSnapshot,
    into backingStore: MetalBackingStore
  ) {
    let context = backingStore.context

    for dirtyRect in dirtyRects {
      let clippedDirtyRect = dirtyRect.intersection(bounds)
      guard !clippedDirtyRect.isNull, !clippedDirtyRect.isEmpty else {
        continue
      }

      context.saveGState()
      context.scaleBy(x: backingStore.scale, y: backingStore.scale)
      context.clear(clippedDirtyRect)
      context.clip(to: clippedDirtyRect)
      draw(snapshot: snapshot, in: context, clipRect: clippedDirtyRect)
      context.restoreGState()

      let scaledRect = clippedDirtyRect
        .applying(.init(scaleX: backingStore.scale, y: backingStore.scale))
        .integral
      guard !scaledRect.isNull, !scaledRect.isEmpty else {
        continue
      }

      let clampedRect = scaledRect.intersection(
        .init(x: 0, y: 0, width: backingStore.width, height: backingStore.height)
      )
      guard !clampedRect.isNull, !clampedRect.isEmpty else {
        continue
      }

      let bytesOffset = Int(clampedRect.minY) * backingStore.bytesPerRow + Int(clampedRect.minX) * 4
      backingStore.texture.replace(
        region: .init(
          origin: .init(x: Int(clampedRect.minX), y: Int(clampedRect.minY), z: 0),
          size: .init(width: Int(clampedRect.width), height: Int(clampedRect.height), depth: 1)
        ),
        mipmapLevel: 0,
        withBytes: backingStore.data.advanced(by: bytesOffset),
        bytesPerRow: backingStore.bytesPerRow
      )
    }
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
      pendingDirtyRects.withLock { dirtyRects in
        if clippedDirtyRect == bounds {
          dirtyRects = [clippedDirtyRect]
        } else if dirtyRects != [bounds] {
          dirtyRects.append(clippedDirtyRect)
        }
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
