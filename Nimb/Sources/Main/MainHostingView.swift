// SPDX-License-Identifier: MIT

import AppKit
import CoreMedia
import IOSurface

public class MainHostingView: NSView {
  override public var wantsUpdateLayer: Bool {
    true
  }

  private var ioSurface: IOSurface?

  override public init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func updateLayer() {
    if ioSurface == nil {
      ioSurface = IOSurface(properties: [
        .width: layer!.bounds.width * layer!.contentsScale,
        .height: layer!.bounds.height * layer!.contentsScale,
        .pixelFormat: kCMPixelFormat_32BGRA,
        .bytesPerElement: 4,
      ])
    }
    layer!.contents = ioSurface
  }
}
