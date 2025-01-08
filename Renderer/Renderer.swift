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
        await gridRenderer.set(gridContext: gridContext)
      } else {
        let gridRenderer = await GridRenderer(
          gridID: gridID,
          gridContext: gridContext
        )
        self.gridRenderers[gridID] = gridRenderer
      }
      cb()
    }
  }

  @objc public func draw(
    gridDrawRequest: GridDrawRequest,
    forGridWithID gridID: Int,
    _ cb: @escaping @Sendable () -> Void
  ) {
    asyncQueue.addOperation {
      await self.gridRenderers[gridID]!.draw(gridDrawRequest: gridDrawRequest, cb)
    }
  }
}
