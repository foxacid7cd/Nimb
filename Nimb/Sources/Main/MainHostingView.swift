// SPDX-License-Identifier: MIT

import AppKit
import CoreMedia
import IOSurface

public class MainHostingView: NSView {
  override public var wantsUpdateLayer: Bool {
    true
  }

  private var connectionToService: NSXPCConnection?
  private var ioSurface: IOSurface?

  override public init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    Task { @MainActor in
      connectionToService?.invalidate()
    }
  }

  override public func updateLayer() {
    if ioSurface == nil {
      ioSurface = IOSurface(properties: [
        .width: layer!.bounds.width * layer!.contentsScale,
        .height: layer!.bounds.height * layer!.contentsScale,
        .pixelFormat: kCMPixelFormat_32BGRA,
        .bytesPerElement: 4,
      ])

      startRenderer(with: ioSurface!)
    }
    layer!.contents = ioSurface
  }

  private func startRenderer(with ioSurface: IOSurface) {
    connectionToService = NSXPCConnection(serviceName: "foxacid7cd.Renderer")
    connectionToService!.remoteObjectInterface = NSXPCInterface(with: RendererProtocol.self)
    connectionToService!.resume()

    if let proxy = connectionToService!.remoteObjectProxy as? RendererProtocol {
      proxy
        .setup(
          ioSurface: ioSurface,
          scale: layer!.contentsScale
        ) { @Sendable string in
          logger.info("Reply: \(string)")
        }
    }
  }
}
