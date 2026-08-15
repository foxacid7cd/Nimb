// SPDX-License-Identifier: MIT

// Driven from GridLayer, which stays off the main actor because CALayer's
// overrides are nonisolated. The types here are explicitly nonisolated so the
// app target's MainActor default does not reach them.

import AppKit
import CoreText
import Metal

final nonisolated class GridMetalGlyphAtlas {
  struct GlyphKey: Hashable {
    let fontID: Int
    let glyph: CGGlyph
  }

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

  let texture: MTLTexture
  let scale: CGFloat

  private var entries: [GlyphKey: GlyphEntry] = [:]

  /// Fonts are interned to a small Int so the per-glyph lookup key holds no
  /// String. The key used to carry font.fontName, which bridged an NSString
  /// out of AppKit and hashed it once per glyph per frame.
  ///
  /// Identity is the fast path; the descriptor map behind it is what keeps two
  /// distinct NSFont instances describing the same font sharing atlas entries,
  /// so interning cannot silently duplicate rasterizations. Both maps are
  /// bounded by the number of live NSFont instances, which FontBridge holds
  /// fixed at four per configured font.
  private var fontIDsByIdentity: [ObjectIdentifier: Int] = [:]
  private var fontIDsByDescriptor: [FontDescriptor: Int] = [:]
  /// Retains every interned font: ObjectIdentifier is only meaningful while
  /// the object it came from is alive, and an address can be reused.
  private var internedFonts: [NSFont] = []
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
    let key = GlyphKey(fontID: fontID(for: font), glyph: glyph)
    if let entry = entries[key] {
      return entry
    }

    guard let rasterizedGlyph = rasterizeGlyph(glyph: glyph, font: font) else {
      return nil
    }

    return place(rasterizedGlyph: rasterizedGlyph, for: key)
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
    return fontID
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
