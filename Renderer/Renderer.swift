// SPDX-License-Identifier: MIT

import AppKit
import CoreGraphics
import IOSurface
import QuartzCore

final class Renderer: NSObject, RendererProtocol, @unchecked Sendable, GridRendererDelegate {
  var remoteRendererClient: RendererClientProtocol?

  private var fontState: FontState?
  private var contentsScale: CGFloat?
  private var gridRenderers: [Int: GridRenderer] = [:]

  func gridRendererDidRecreateIOSurface(_ gridRenderer: GridRenderer) {
    remoteRendererClient?
      .set(
        ioSurface: gridRenderer.ioSurface,
        forGridWithID: gridRenderer.gridID
      )
  }

  @objc func setFont(_ font: NSFont, cb: @escaping (CGSize) -> Void) {
    fontState = FontState(font)
    for gridRenderer in gridRenderers.values {
      gridRenderer.set(fontState: fontState!)
    }
    cb(fontState!.cellSize)
  }

  @objc func set(contentsScale: CGFloat, _ cb: @escaping (_ isChanged: Bool) -> Void) {
    if contentsScale != self.contentsScale {
      self.contentsScale = contentsScale
      for gridRenderer in gridRenderers.values {
        gridRenderer.set(contentsScale: contentsScale)
      }
      cb(true)
    } else {
      cb(false)
    }
  }

  @objc func setGridSize(columnsCount: Int, rowsCount: Int, forGridWithID gridID: Int, _ cb: @Sendable (_ isChanged: Bool) -> Void) {
    assertInitialized()

    let gridSize = IntegerSize(columnsCount: columnsCount, rowsCount: rowsCount)

    if let gridRenderer = gridRenderers[gridID] {
      let isChanged = gridRenderer.set(gridSize: gridSize)
      cb(isChanged)
    } else {
      let newGridRenderer = GridRenderer(
        gridID: gridID,
        contentsScale: contentsScale!,
        fontState: fontState!,
        gridSize: gridSize
      )
      remoteRendererClient?
        .set(ioSurface: newGridRenderer.ioSurface, forGridWithID: gridID)
      newGridRenderer.delegate = self
      gridRenderers[gridID] = newGridRenderer
      cb(true)
    }
  }

  @objc func register(
    ioSurface: IOSurface,
    scale: CGFloat,
    forGridWithID gridID: Int,
    cb: @escaping @Sendable (Bool) -> Void
  ) {
    cb(true)
  }

  @objc func draw(
    gridDrawRequest: GridDrawRequest,
    cb: @Sendable @escaping () -> Void
  ) {
    gridRenderers[gridDrawRequest.gridID]?.draw(gridDrawRequest: gridDrawRequest)
    cb()
  }

  private func assertInitialized(file: StaticString = #file, line: UInt = #line) {
    precondition(
      fontState != nil,
      "Font must be set before calling this method",
      file: file,
      line: line
    )
    precondition(
      contentsScale != nil,
      "Contents scale must be set before calling this method",
      file: file,
      line: line
    )
  }
}
