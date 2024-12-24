// SPDX-License-Identifier: MIT

import AppKit
import CoreGraphics
import IOSurface
import QuartzCore

/// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service
/// over an NSXPCConnection.
final class Renderer: NSObject, RendererProtocol {
  var gridRenderers: [Int: GridRenderer] = [:]

  @objc func register(
    ioSurface: IOSurface,
    scale: CGFloat,
    forGridWithID gridID: Int,
    cb: @escaping @Sendable (Bool) -> Void
  ) {
    gridRenderers.removeValue(forKey: gridID)
    gridRenderers[gridID] = .init(
      ioSurface: ioSurface,
      scale: scale,
      gridID: gridID
    )
    cb(true)
  }

  @objc func render(
    color: NSColor,
    in rect: CGRect,
    forGridWithID gridID: Int,
    cb: @escaping (Bool) -> Void
  ) {
    gridRenderers[gridID]?.render(color: color, in: rect)
    cb(true)
  }
}
