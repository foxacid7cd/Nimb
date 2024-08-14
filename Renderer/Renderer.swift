// SPDX-License-Identifier: MIT

import AppKit
import CoreGraphics
import IOSurface
import QuartzCore

/// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service
/// over an NSXPCConnection.
class Renderer: NSObject, RendererProtocol {
  @objc func setup(ioSurface: IOSurface, scale: Double, reply: @escaping (String) -> Void) {
    ioSurface.lock(options: [], seed: nil)
    defer { ioSurface.unlock(options: [], seed: nil) }

    let cgContext = CGContext(
      data: ioSurface.baseAddress,
      width: ioSurface.width,
      height: ioSurface.height,
      bitsPerComponent: 8,
      bytesPerRow: ioSurface.bytesPerRow,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )!
    cgContext.scaleBy(x: scale, y: scale)
    let graphicsContext = NSGraphicsContext(cgContext: cgContext, flipped: false)
    NSGraphicsContext.current = graphicsContext

    graphicsContext.shouldAntialias = true
    NSAttributedString(
      string: "Hello world!",
      attributes: [
        .foregroundColor: NSColor.green,
        .font: NSFont.systemFont(ofSize: 40, weight: .medium),
      ]
    )
    .draw(at: .init(x: 100, y: 100))

    graphicsContext.flushGraphics()
  }
}
