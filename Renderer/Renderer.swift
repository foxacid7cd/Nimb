// SPDX-License-Identifier: MIT

import AppKit
import CoreGraphics
@preconcurrency import IOSurface
import QuartzCore
import Queue

public final class Renderer: NSObject, RendererProtocol, @unchecked Sendable {
  private let asyncQueue = AsyncQueue()
  private var gridRenderers = IntKeyedDictionary<GridRenderer>()

  @objc public func execute(
    renderOperations: GridRenderOperations,
    forGridWithID gridID: Int,
    _ cb: @Sendable @escaping (_ result: GridRenderOperationsResult) -> Void
  ) {
    asyncQueue.addOperation {
      if self.gridRenderers[gridID] == nil {
        self.gridRenderers[gridID] = .init(gridID: gridID)
      }

      self.gridRenderers[gridID]!
        .execute(renderOperations: renderOperations, cb)
    }
  }
}
