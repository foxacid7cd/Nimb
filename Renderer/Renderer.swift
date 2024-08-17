// SPDX-License-Identifier: MIT

import AppKit
import CoreGraphics
import IOSurface
import QuartzCore

/// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service
/// over an NSXPCConnection.
final class Renderer: NSObject, RendererProtocol {
  private var sharedMemoryBaseAddress: UnsafeMutableRawPointer?
  private var sharedMemorySize = 0

  private var gridRenderers = IntKeyedDictionary<GridRenderer>()
  private var state = State()
  private let unpacker = Unpacker()

  @objc func set(
    sharedMemoryXPC: xpc_object_t,
    reply: @escaping @Sendable () -> Void
  ) {
    sharedMemorySize = xpc_shmem_map(
      sharedMemoryXPC,
      &sharedMemoryBaseAddress
    )
    reply()
  }

  @objc func processNvimOutputData(count: Int, offset: Int, reply: @Sendable @escaping () -> Void) {
    do {
      let messages = try unpacker
        .unpack(
          .init(
            start: sharedMemoryBaseAddress!
              .advanced(by: offset),
            count: count
          )
        )
        .map { try Message(value: $0) }
      for message in messages {
        switch message {
        case let .notification(notification):
          if notification.method == "redraw" {
            let uiEvents = try [UIEvent](
              rawRedrawNotificationParameters: notification.parameters
            )
            let updates = state.apply(uiEvents)
            dump(updates)
          }

        default:
          break
        }
      }
    } catch {
      dump(error)
    }
    reply()
  }

  @objc func register(
    surface: IOSurface,
    scale: CGFloat,
    forGridWithID gridID: Int,
    cb: @escaping @Sendable (Bool) -> Void
  ) {
    gridRenderers.removeValue(forKey: gridID)
    gridRenderers[gridID] = .init(
      surface: surface,
      scale: scale,
      gridID: gridID
    )

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
