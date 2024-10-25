// SPDX-License-Identifier: MIT

import AppKit
import IOSurface

final class GridRenderer {
  private let surface: IOSurface
  private let scale: CGFloat
  private let gridID: Int

  init(surface: IOSurface, scale: CGFloat, gridID: Int) {
    self.surface = surface
    self.scale = scale
    self.gridID = gridID
  }

  func render(state: State, updates: State.Updates) {
    if updates.isAppearanceChanged {
      surface.lock(options: [], seed: nil)
      defer { surface.unlock(options: [], seed: nil) }

      let cgContext = CGContext(
        data: surface.baseAddress,
        width: surface.width,
        height: surface.height,
        bitsPerComponent: 8,
        bytesPerRow: surface.bytesPerRow,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
      )!
      cgContext.scaleBy(x: scale, y: scale)
      NSGraphicsContext.current = .init(
        cgContext: cgContext,
        flipped: false
      )

      let graphicsContext = NSGraphicsContext.current!
      defer { graphicsContext.flushGraphics() }

      NSColor.red.withAlphaComponent(0.8).setFill()
      NSRect(
        origin: .zero,
        size: .init(width: 200, height: 200)
      ).fill()
    }
  }
}
