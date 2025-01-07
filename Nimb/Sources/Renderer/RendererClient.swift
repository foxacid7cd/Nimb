// SPDX-License-Identifier: MIT

@preconcurrency import AppKit

public protocol RendererClientDelegate: AnyObject, Sendable {
  @MainActor
  func rendererClientDidSet(ioSurface: IOSurface, forGridWithID gridID: Int)
}

public final class RendererClient: NSObject, RendererClientProtocol {
  @MainActor
  public weak var delegate: RendererClientDelegate?

  public func set(ioSurface: IOSurface, forGridWithID gridID: Int) {
    Task {
      await delegate?.rendererClientDidSet(ioSurface: ioSurface, forGridWithID: gridID)
    }
  }
}
