// SPDX-License-Identifier: MIT

import AppKit
import CustomDump
import IOSurface
import Queue

protocol GridRendererDelegate: AnyObject {
  func gridRendererDidRecreateIOSurface(_ gridRenderer: GridRenderer)
}

final class GridRenderer {
  weak var delegate: GridRendererDelegate?

  let gridID: Int

  private(set) var ioSurface: IOSurface

  private var contentsScale: CGFloat
  private var fontState: FontState
  private var gridSize: IntegerSize

  private var cellSize: CGSize {
    fontState.cellSize
  }

  init(
    gridID: Int,
    contentsScale: CGFloat,
    fontState: FontState,
    gridSize: IntegerSize
  ) {
    self.gridID = gridID
    self.contentsScale = contentsScale
    self.fontState = fontState
    self.gridSize = gridSize
    ioSurface = Self.createIOSurface(
      contentsScale: contentsScale,
      gridSize: gridSize,
      cellSize: fontState.cellSize
    )
  }

  private static func createIOSurface(contentsScale: CGFloat, gridSize: IntegerSize, cellSize: CGSize) -> IOSurface {
    .init(
      properties: [
        .width: CGFloat(gridSize.columnsCount) * cellSize.width * contentsScale,
        .height: CGFloat(
          gridSize.rowsCount
        ) * cellSize.height * contentsScale,
        .bytesPerElement: 4,
        .pixelFormat: kCVPixelFormatType_32BGRA,
      ]
    )!
  }

  func set(fontState: FontState) {
    self.fontState = fontState
    recreateIOSurface()
  }

  func set(contentsScale: CGFloat) {
    self.contentsScale = contentsScale
    recreateIOSurface()
  }

  func set(gridSize: IntegerSize) -> Bool {
    guard gridSize != self.gridSize else {
      return false
    }

    self.gridSize = gridSize
    recreateIOSurface()

    return true
  }

  func draw(gridDrawRequest: GridDrawRequest) {
    ioSurface.lock(seed: nil)

    let cgContext = CGContext(
      data: ioSurface.baseAddress,
      width: ioSurface.width,
      height: ioSurface.height,
      bitsPerComponent: 8,
      bytesPerRow: ioSurface.bytesPerRow,
      space: CGColorSpace(name: CGColorSpace.sRGB)!,
      bitmapInfo: CGBitmapInfo(
        rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue
      )
      .union(.byteOrder32Little)
      .rawValue
    )!

    cgContext.setShouldAntialias(false)
    for part in gridDrawRequest.parts {
      let frame = IntegerRectangle(
        origin: .init(column: part.columnsRange.lowerBound, row: part.row),
        size: .init(columnsCount: part.columnsRange.count, rowsCount: 1)
      )
      cgContext.setFillColor(part.backgroundColor.cg)
      cgContext.fill(frame * cellSize * contentsScale)
    }

    cgContext.setShouldAntialias(true)
    for part in gridDrawRequest.parts {
      cgContext.saveGState()

      let attributedString = NSAttributedString(
        string: part.text,
        attributes: [
          .font: fontState.nsFontForDraw(for: part),
          .foregroundColor: part.foregroundColor.appKit,
        ]
      )
      let line = CTLineCreateWithAttributedString(attributedString)
      cgContext.textPosition = .init(
        x: Double(part.columnsRange.lowerBound) * cellSize.width,
        y: Double(
          part.row
        ) * cellSize.height - fontState.regular.boundingRectForFont.origin.y
      )
      cgContext.scaleBy(x: contentsScale, y: contentsScale)
      CTLineDraw(line, cgContext)

      cgContext.restoreGState()
    }

    cgContext.flush()

    ioSurface.unlock(seed: nil)
  }

  private func recreateIOSurface() {
    ioSurface = Self.createIOSurface(
      contentsScale: contentsScale,
      gridSize: gridSize,
      cellSize: cellSize
    )
    delegate?.gridRendererDidRecreateIOSurface(self)
  }
}
