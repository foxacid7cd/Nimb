// SPDX-License-Identifier: MIT

import AppKit

@objc public protocol RendererProtocol: AnyObject, Sendable {
  @objc func register(gridContext: GridContext, forGridWithID gridID: Int, _ cb: @Sendable @escaping () -> Void)
  @objc func draw(
    gridDrawRequest: GridDrawRequest,
    forGridWithID gridID: Int,
    _ cb: @Sendable @escaping () -> Void
  )
}
