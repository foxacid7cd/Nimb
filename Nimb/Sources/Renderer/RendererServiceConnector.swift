// SPDX-License-Identifier: MIT

import AppKit
import Darwin
import Foundation
import IOSurface

@MainActor
public class RendererServiceConnector {
  private var connectionToService: NSXPCConnection?

  public func connect() async -> RendererProtocol {
    let connectionToService = NSXPCConnection(serviceName: "foxacid7cd.Renderer")
    self.connectionToService = connectionToService

    connectionToService.remoteObjectInterface = NSXPCInterface(with: RendererProtocol.self)
    let remoteRenderer = connectionToService.remoteObjectProxy as! RendererProtocol

    connectionToService.resume()

    return remoteRenderer
  }

  public func invalidate() {
    connectionToService?.invalidate()
  }
}
