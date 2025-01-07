// SPDX-License-Identifier: MIT

import AppKit
import IOSurface

@objc public protocol RendererClientProtocol: Sendable {
  @objc func set(ioSurface: IOSurface, forGridWithID gridID: Int)
}
