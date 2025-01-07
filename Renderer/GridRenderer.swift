// SPDX-License-Identifier: MIT

import AppKit
import CustomDump
import IOSurface
import Queue

public final class GridRenderer: @unchecked Sendable {
  public let gridID: Int

  private var gridContext: GridContext
  private var fontState: FontState
  private let asyncQueue = AsyncQueue()

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
  }

  public func set(gridContext: GridContext) {
    asyncQueue.addOperation {
      self.gridContext = gridContext
      self.fontState = .init(gridContext.font)
    }
  }

  public func draw(gridDrawRequest: GridDrawRequest) {
    asyncQueue.addOperation {
      self.ioSurface.lock(seed: nil)

      let cgContext = CGContext(
        data: self.ioSurface.baseAddress,
        width: self.ioSurface.width,
        height: self.ioSurface.height,
        bitsPerComponent: 8,
        bytesPerRow: self.ioSurface.bytesPerRow,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
      )!

      cgContext.setShouldAntialias(false)
      for part in gridDrawRequest.parts {
        let frame = IntegerRectangle(
          origin: .init(column: part.columnsRange.lowerBound, row: part.row),
          size: .init(columnsCount: part.columnsRange.count, rowsCount: 1)
        )
        cgContext.setFillColor(part.backgroundColor.cg)
        cgContext.fill(frame * self.cellSize * self.contentsScale)
      }

      cgContext.setShouldAntialias(true)
      for part in gridDrawRequest.parts {
        cgContext.saveGState()

        let attributedString = NSAttributedString(
          string: part.text,
          attributes: [
            .font: self.fontState.nsFontForDraw(for: part),
            .foregroundColor: part.foregroundColor.appKit,
          ]
        )
        let line = CTLineCreateWithAttributedString(attributedString)
        cgContext.textPosition = .init(
          x: Double(part.columnsRange.lowerBound) * self.cellSize.width,
          y: Double(
            part.row
          ) * self.cellSize.height - self.fontState.regular.boundingRectForFont.origin.y
        )
        cgContext.scaleBy(x: self.contentsScale, y: self.contentsScale)
        CTLineDraw(line, cgContext)

        cgContext.restoreGState()
      }

      cgContext.flush()

      self.ioSurface.unlock(seed: nil)
    }
  }
}
