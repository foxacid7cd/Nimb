// SPDX-License-Identifier: MIT

import AppKit

@objc public protocol RendererProtocol: AnyObject, Sendable {
  @objc func execute(
    renderOperations: GridRenderOperations,
    forGridWithID gridID: Int,
    _ cb: @Sendable @escaping (
      _ result: GridRenderOperationsResult
    ) -> Void
  )
}
