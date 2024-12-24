// SPDX-License-Identifier: MIT

import AppKit
import Darwin
import Foundation
import IOSurface

@MainActor
public final class RemoteRenderer {
  private let connectionToService = NSXPCConnection(
    serviceName: "foxacid7cd.Renderer"
  )
  private let proxy: RendererProtocol
  private var currentOffset = 0

  public init() async {
    connectionToService.remoteObjectInterface = NSXPCInterface(
      with: RendererProtocol.self
    )
    connectionToService.resume()

    proxy = connectionToService.remoteObjectProxy as! RendererProtocol
  }

  public func invalidate() {
    connectionToService.invalidate()
  }

  public func register(
    ioSurface: IOSurface,
    scale: CGFloat,
    forGridWithID gridID: Int
  ) {
    proxy
      .register(
        ioSurface: ioSurface,
        scale: scale,
        forGridWithID: gridID
      ) { isSuccess in
        if !isSuccess {
          logger.error("Failed to register surface")
        }
      }
  }

  public func render(
    color: NSColor,
    in rect: CGRect,
    forGridWithID gridID: Int
  ) {
    proxy
      .render(
        color: color,
        in: rect,
        forGridWithID: gridID
      ) { isSuccess in
        if !isSuccess {
          logger.error("Failed to render color")
        }
      }
  }

  public func processNvimOutput(data: Data) {
    //    proxy
    //      .processNvimOutputData(
    //        count: data.count,
    //        offset: currentOffset
    //      ) { }
  }
}
