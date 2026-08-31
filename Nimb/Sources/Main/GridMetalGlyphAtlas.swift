// SPDX-License-Identifier: MIT

// Explicitly nonisolated, so the app target's MainActor default does not reach
// types driven from GridLayer's nonisolated CALayer overrides.

import AppKit
import CoreText
import Metal
import NimbCore

final nonisolated class GridMetalGlyphAtlas {
  struct GlyphEntry {
    let origin: SIMD2<Float>
    let size: SIMD2<Float>
    let uvOrigin: SIMD2<Float>
    let uvSize: SIMD2<Float>
  }

  /// Identifies a font the way the atlas cares about it. Only consulted the
  /// first time a given NSFont instance is seen.
  private struct FontDescriptor: Hashable {
    let name: String
    let pointSize: CGFloat
  }

  private struct RasterizedGlyph {
    let bytes: [UInt8]
    let width: Int
    let height: Int
    let origin: SIMD2<Float>
    let size: SIMD2<Float>
  }

  /// Replaced wholesale rather than cleared when the atlas fills up, so any
  /// frame still in flight keeps sampling the texture it was built against.
  private(set) var texture: MTLTexture
  let scale: CGFloat

  private let device: MTLDevice
  private let textureSize: Int

  /// Entries indexed by (fontID << 16 | glyph) rather than hashed, since this
  /// runs once per glyph per frame. UInt32.max marks an empty slot.
  private var entryIndices: [UInt32] = []
  private var entries: [GlyphEntry] = []

  /// Fonts interned to a small Int, so the per-glyph key holds no String. The
  /// descriptor map behind identity stops equal fonts duplicating entries.
  private var fontIDsByIdentity: [ObjectIdentifier: Int] = [:]
  private var fontIDsByDescriptor: [FontDescriptor: Int] = [:]
  /// Retains every interned font: ObjectIdentifier is only meaningful while
  /// the object it came from is alive, and an address can be reused.
  private var internedFonts: [NSFont] = []
  private var nextX = 0
  private var nextY = 0
  private var rowHeight = 0

  init?(renderer: GridMetalRenderer, scale: CGFloat, size: Int = 4096) {
    guard let texture = Self.makeTexture(device: renderer.device, size: size) else {
      return nil
    }

    device = renderer.device
    textureSize = size
    self.texture = texture
    self.scale = scale
  }

  private static func makeTexture(device: MTLDevice, size: Int) -> MTLTexture? {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .r8Unorm,
      width: size,
      height: size,
      mipmapped: false,
    )
    descriptor.usage = [.shaderRead]
    descriptor.storageMode = device.hasUnifiedMemory ? .shared : .managed

    guard let texture = device.makeTexture(descriptor: descriptor) else {
      return nil
    }

    // Metal makes no promise about the initial contents, and anything sampled
    // outside a placed glyph has to read as fully transparent.
    let zero = [UInt8](repeating: 0, count: size * size)
    texture.replace(
      region: .init(origin: .init(x: 0, y: 0, z: 0), size: .init(width: size, height: size, depth: 1)),
      mipmapLevel: 0,
      withBytes: zero,
      bytesPerRow: size,
    )
    return texture
  }

  func entry(for glyph: CGGlyph, font: NSFont) -> GlyphEntry? {
    let slot = fontID(for: font) << 16 | Int(glyph)
    let index = entryIndices[slot]
    if index != .max {
      return entries[Int(index)]
    }

    guard let rasterizedGlyph = rasterizeGlyph(glyph: glyph, font: font) else {
      return nil
    }

    return place(rasterizedGlyph: rasterizedGlyph, at: slot)
  }

  private func fontID(for font: NSFont) -> Int {
    let identity = ObjectIdentifier(font)
    if let fontID = fontIDsByIdentity[identity] {
      return fontID
    }

    let descriptor = FontDescriptor(name: font.fontName, pointSize: font.pointSize)
    let fontID: Int
    if let existing = fontIDsByDescriptor[descriptor] {
      fontID = existing
    } else {
      fontID = fontIDsByDescriptor.count
      fontIDsByDescriptor[descriptor] = fontID
    }

    internedFonts.append(font)
    fontIDsByIdentity[identity] = fontID

    let required = (fontID + 1) << 16
    if entryIndices.count < required {
      entryIndices.append(
        contentsOf: repeatElement(.max, count: required - entryIndices.count),
      )
    }

    return fontID
  }

  private func rasterizeGlyph(glyph: CGGlyph, font: NSFont) -> RasterizedGlyph? {
    measuringRenderStage("glyph raster", .glyphRasterize) {
      rasterizeGlyphUncounted(glyph: glyph, font: font)
    }
  }

  private func rasterizeGlyphUncounted(glyph: CGGlyph, font: NSFont) -> RasterizedGlyph? {
    let ctFont = font as CTFont
    var glyph = glyph
    var bounds = CTFontGetBoundingRectsForGlyphs(ctFont, .default, &glyph, nil, 1)

    if bounds.isNull || bounds.isInfinite {
      bounds = .zero
    }

    // Two pixels rather than one: smoothing dilates the stems, and a glyph
    // that touches the edge of its rasterisation would lose that dilation.
    let paddingPoints = 2 / max(scale, 1)
    let paddedBounds = bounds.insetBy(dx: -paddingPoints, dy: -paddingPoints)

    // Snapped down to a whole device pixel before rasterising, so the mapping
    // is exactly one texel per pixel and the sampler does not resample.
    let originX = (paddedBounds.minX * scale).rounded(.down) / scale
    let originY = (paddedBounds.minY * scale).rounded(.down) / scale
    let pixelWidth = max(1, Int(ceil((paddedBounds.maxX - originX) * scale)))
    let pixelHeight = max(1, Int(ceil((paddedBounds.maxY - originY) * scale)))
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

    // Drawn as a glyph rather than as a filled outline, which would get none
    // of the font smoothing CoreGraphics applies to text.
    context.setShouldAntialias(true)
    context.setAllowsAntialiasing(true)
    // Smoothing dilates the stems, which at this size is what keeps most of a
    // stem's pixels fully covered rather than half covered.
    context.setShouldSmoothFonts(true)
    context.setAllowsFontSmoothing(true)
    context.setFillColor(gray: 1, alpha: 1)
    context.setTextDrawingMode(.fill)

    context.translateBy(x: 0, y: CGFloat(pixelHeight))
    context.scaleBy(x: scale, y: -scale)
    context.translateBy(x: -originX, y: -originY)

    var position = CGPoint.zero
    CTFontDrawGlyphs(ctFont, &glyph, &position, 1, context)

    return .init(
      bytes: bytes,
      width: pixelWidth,
      height: pixelHeight,
      origin: .init(Float(originX), Float(originY)),
      size: .init(Float(CGFloat(pixelWidth) / scale), Float(CGFloat(pixelHeight) / scale)),
    )
  }

  private func place(
    rasterizedGlyph: RasterizedGlyph,
    at slot: Int,
  )
  -> GlyphEntry? {
    if rasterizedGlyph.width > texture.width || rasterizedGlyph.height > texture.height {
      return nil
    }

    if nextX + rasterizedGlyph.width > texture.width {
      nextX = 0
      nextY += rowHeight
      rowHeight = 0
    }

    if nextY + rasterizedGlyph.height > texture.height, !reset() {
      return nil
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
    entryIndices[slot] = UInt32(entries.count)
    entries.append(entry)

    nextX += rasterizedGlyph.width + 1
    rowHeight = max(rowHeight, rasterizedGlyph.height + 1)

    return entry
  }

  /// Starts over in a brand new texture rather than zeroing this one, which a
  /// command buffer from the previous frame may still be sampling.
  private func reset() -> Bool {
    guard let texture = Self.makeTexture(device: device, size: textureSize) else {
      return false
    }

    self.texture = texture
    entries.removeAll(keepingCapacity: true)
    for index in entryIndices.indices {
      entryIndices[index] = .max
    }
    nextX = 0
    nextY = 0
    rowHeight = 0
    return true
  }
}
