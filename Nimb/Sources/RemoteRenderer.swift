// SPDX-License-Identifier: MIT

import Foundation
import IOSurface

public final class RemoteRenderer {
  public var proxy: RendererProtocol!

  private let connectionToService = NSXPCConnection(serviceName: "foxacid7cd.Renderer")

  public init() {
    connectionToService.remoteObjectInterface = NSXPCInterface(with: RendererProtocol.self)
    connectionToService.resume()

    proxy = connectionToService.remoteObjectProxy as? RendererProtocol
  }

  public func invalidate() {
    connectionToService.invalidate()
  }
}
