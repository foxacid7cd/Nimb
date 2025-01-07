// SPDX-License-Identifier: MIT

import AppKit
import Darwin
import Foundation
import IOSurface

@MainActor
public class RendererServiceConnector {
  private let rendererClient = RendererClient()
  private var connectionToService: NSXPCConnection?
  private var proxy: RendererProtocol?

  public var rendererClientDelegate: RendererClientDelegate? {
    get {
      rendererClient.delegate
    }
    set {
      rendererClient.delegate = newValue
    }
  }

  public func connect() async -> RendererProtocol {
    let connectionToService = NSXPCConnection(serviceName: "foxacid7cd.Renderer")
    self.connectionToService = connectionToService

    connectionToService.exportedInterface = NSXPCInterface(
      with: RendererClientProtocol.self
    )
    connectionToService.exportedObject = rendererClient

    connectionToService.remoteObjectInterface = NSXPCInterface(with: RendererProtocol.self)

    connectionToService.resume()

    return connectionToService.remoteObjectProxy as! RendererProtocol
  }

  public func invalidate() {
    connectionToService?.invalidate()
  }
}
