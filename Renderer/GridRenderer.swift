// SPDX-License-Identifier: MIT

import AppKit
import CustomDump
import IOSurface
import Queue

@RenderActor
public final class GridRenderer {
  public let gridID: Int

  private var gridContext: GridContext
  private var fontState: FontState
  private var cgContext: CGContext

  private var ioSurface: IOSurface {
    gridContext.ioSurface
  }

  private var gridSize: IntegerSize {
    gridContext.size
  }

  private var cellSize: CGSize {
    fontState.cellSize
  }

  private var contentsScale: CGFloat {
    gridContext.contentsScale
  }

  public init(
    gridID: Int,
    gridContext: GridContext
  ) {
    self.gridID = gridID
    self.gridContext = gridContext
    fontState = .init(gridContext.font)
    cgContext = Self.makeCGContext(ioSurface: gridContext.ioSurface)
  }

  private static func makeCGContext(ioSurface: IOSurface) -> CGContext {
    .init(
      data: ioSurface.baseAddress,
      width: ioSurface.width,
      height: ioSurface.height,
      bitsPerComponent: 8,
      bytesPerRow: ioSurface.bytesPerRow,
      space: CGColorSpace(name: CGColorSpace.sRGB)!,
      bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
    )!
  }

  public func set(gridContext: GridContext) {
    self.gridContext = gridContext
    fontState = .init(gridContext.font)
    cgContext = Self.makeCGContext(ioSurface: gridContext.ioSurface)
  }

  public func draw(
    gridDrawRequest: GridDrawRequest,
    _ cb: @Sendable @escaping () -> Void
  ) {
    ioSurface.lock(seed: nil)

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

    cb()
  }
}
