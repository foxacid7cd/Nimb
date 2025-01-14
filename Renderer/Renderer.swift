// SPDX-License-Identifier: MIT

import AppKit
import CoreGraphics
@preconcurrency import IOSurface
import QuartzCore
import Queue

public final class Renderer: NSObject, RendererProtocol, @unchecked Sendable {
  private let asyncQueue = AsyncQueue(attributes: .concurrent)
  private var gridRenderers = IntKeyedDictionary<GridRenderer>()

  @objc public func register(
    gridContext: GridContext,
    forGridWithID gridID: Int,
    _ cb: @Sendable @escaping () -> Void
  ) {
    asyncQueue.addBarrierOperation {
      if let gridRenderer = self.gridRenderers[gridID] {
        gridRenderer.set(gridContext: gridContext)
      } else {
        let gridRenderer = GridRenderer(
          gridID: gridID,
          gridContext: gridContext
        )
        self.gridRenderers[gridID] = gridRenderer
      }
      cb()
    }
  }

  @objc public func execute(renderOperations: GridRenderOperations, forGridWithID gridID: Int, _ cb: @Sendable @escaping () -> Void) {
    asyncQueue.addOperation {
      self.gridRenderers[gridID]!
        .execute(renderOperations: renderOperations, cb)
    }
  }
}
