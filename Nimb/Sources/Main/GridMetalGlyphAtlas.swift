// SPDX-License-Identifier: MIT

// Driven from GridLayer, which stays off the main actor because CALayer's
// overrides are nonisolated. The types here are explicitly nonisolated so the
// app target's MainActor default does not reach them.

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

  /// Entries indexed by (fontID << 16 | glyph) rather than held in a
  /// Dictionary. This lookup runs once per glyph per frame -- tens of thousands
  /// of times a second -- and profiling the Metal path found hashing that key
  /// to be the single largest cost inside scene building, larger than encoding
  /// the draw calls. Both halves of the key are small and dense, so a flat
  /// table removes the hash and the probe entirely.
  ///
  /// UInt32.max marks an empty slot. A slot per glyph id costs 256KB per font,
  /// and FontBridge holds four fonts per configured font.
  private var entryIndices: [UInt32] = []
  private var entries: [GlyphEntry] = []

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

    // Draw the glyph rather than filling its outline.
    //
    // This used to take CTFontCreatePathForGlyph and fillPath, which is not
    // text rendering: a path fill gets none of the font smoothing CoreGraphics
    // applies to glyphs, so every stem came out thinner than the CoreGraphics
    // renderer's, which draws through CTFontDrawGlyphs with smoothing on. The
    // atlas now asks for the same treatment, so both paths shape the same
    // pixels.
    context.setShouldAntialias(true)
    context.setAllowsAntialiasing(true)
    context.setShouldSmoothFonts(true)
    context.setAllowsFontSmoothing(true)
    context.setFillColor(gray: 1, alpha: 1)
    context.setTextDrawingMode(.fill)

    context.translateBy(x: 0, y: CGFloat(pixelHeight))
    context.scaleBy(x: scale, y: -scale)
    context.translateBy(x: -paddedBounds.minX, y: -paddedBounds.minY)

    var position = CGPoint.zero
    CTFontDrawGlyphs(ctFont, &glyph, &position, 1, context)

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

  /// Starts over in a brand new texture.
  ///
  /// This used to zero the existing one in place, which is both a 16MB write
  /// and unsound now that scene building runs off the main thread: a command
  /// buffer encoded for the previous frame may still be sampling the atlas,
  /// and every glyph it reads would come back blank. Frames hold their atlas
  /// texture by reference, so handing new frames a different one leaves the
  /// old contents intact for exactly as long as something is still using them.
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
