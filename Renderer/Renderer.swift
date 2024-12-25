// SPDX-License-Identifier: MIT

import AppKit
import CoreGraphics
import IOSurface
import QuartzCore

final class Renderer: NSObject, RendererProtocol, @unchecked Sendable {
  var font: NSFont?
  var cellSize: CGSize?
  var gridRenderers: [Int: GridRenderer] = [:]

  @objc func setFont(_ font: NSFont, cb: @escaping (CGSize) -> Void) {
    self.font = font
    let cellSize = CGSize(
      width: font.makeCellWidth(),
      height: font.makeCellHeight()
    )
    self.cellSize = cellSize
    for gridRenderer in gridRenderers.values {
      gridRenderer.setFont(font, cellSize: cellSize)
    }
    cb(cellSize)
  }

  @objc func register(
    ioSurface: IOSurface,
    scale: CGFloat,
    forGridWithID gridID: Int,
    cb: @escaping @Sendable (Bool) -> Void
  ) {
    gridRenderers.removeValue(forKey: gridID)
    gridRenderers[gridID] = .init(
      ioSurface: ioSurface,
      scale: scale,
      gridID: gridID,
      font: font!,
      cellSize: cellSize!
    )
    cb(true)
  }

  @objc func draw(gridDrawRequest: GridDrawRequest) {
    gridRenderers[gridDrawRequest.gridID]?.draw(gridDrawRequest: gridDrawRequest)
  }
}
