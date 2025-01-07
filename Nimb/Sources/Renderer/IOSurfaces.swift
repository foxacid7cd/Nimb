// SPDX-License-Identifier: MIT

import AppKit

public protocol IOSurfacesDelegate: AnyObject {
  @MainActor
  func ioSurfaces(_ ioSurfaces: IOSurfaces, didReceive ioSurface: IOSurface, forGridWithID gridID: Int)
}

@MainActor
public final class IOSurfaces: RendererClientDelegate, Sendable {
  public weak var delegate: IOSurfacesDelegate?

  private var internalStorage = IntKeyedDictionary<IOSurface>()

  public func ioSurface(forGridWithID gridID: Int) -> IOSurface? {
    internalStorage[gridID]
  }

  public func rendererClientDidSet(
    ioSurface: IOSurface,
    forGridWithID gridID: Int
  ) {
    internalStorage[gridID] = ioSurface
    delegate?.ioSurfaces(self, didReceive: ioSurface, forGridWithID: gridID)
  }
}
