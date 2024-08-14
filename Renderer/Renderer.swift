// SPDX-License-Identifier: MIT

import AppKit
import CoreGraphics
import IOSurface
import QuartzCore

/// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service
/// over an NSXPCConnection.
class Renderer: NSObject, RendererProtocol {
  @objc func register(
    surface: IOSurface,
    scale: CGFloat,
    forGridWithID gridID: Int,
    cb: @escaping @Sendable (Bool) -> Void
  ) {
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

    cb(true)
  }
}
