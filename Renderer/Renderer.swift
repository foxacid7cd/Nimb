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
  private var state: State
  private let unpacker = Unpacker()
  private let sharedDrawRunsCache = SharedDrawRunsCache()
  private let handleError = { (error: any Error) in
    _ = dump(error)
  }

  init(initialState: State) {
    state = initialState
  }

  func render() { }

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
            let updates = state.apply(
              uiEvents,
              sharedDrawRunsCache: sharedDrawRunsCache,
              handleError: handleError
            )
            render(state: state, updates: updates)
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
    cb(true)
  }

  private func render(state: State, updates: State.Updates) {
    for (_, gridRenderer) in gridRenderers {
      gridRenderer.render(state: state, updates: updates)
    }
  }
}
