// SPDX-License-Identifier: MIT

import Algorithms
import AppKit
@preconcurrency import CoreText
import CustomDump
import IOSurface
import Queue

public final class GridRenderer: @unchecked Sendable {
  public let gridID: Int

  private var gridContext: GridContext
  private var fontState: FontState
  private var cgContext: CGContext
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
    asyncQueue.addOperation {
      self.ioSurface.lock(seed: nil)
      gridContext.ioSurface.lock(seed: nil)

      let newCGContext = Self.makeCGContext(ioSurface: gridContext.ioSurface)
      newCGContext
        .draw(
          self.cgContext.makeImage()!,
          in: .init(
            origin: .zero,
            size: .init(
              width: gridContext.ioSurface.width,
              height: gridContext.ioSurface.height
            )
          )
        )

      self.ioSurface.unlock(seed: nil)
      gridContext.ioSurface.unlock(seed: nil)

      self.gridContext = gridContext
      self.fontState = .init(gridContext.font)
      self.cgContext = newCGContext
    }
  }

  public func draw(
    gridDrawRequest: GridDrawRequest,
    _ cb: @Sendable @escaping () -> Void
  ) {
    asyncQueue.addOperation {
      let fontState = self.fontState

      let chunkSize = gridDrawRequest.parts.count > 20 ? gridDrawRequest.parts.count / 2 : 1

      let chunks = await withTaskGroup(of: (chunkIndex: Int, lines: [CTLine]).self) { taskGroup in
        let partsChunks = gridDrawRequest.parts
          .chunks(ofCount: chunkSize)

        partsChunks
          .enumerated()
          .forEach { chunkIndex, parts in
            taskGroup.addTask {
              let lines = [CTLine](
                unsafeUninitializedCapacity: parts.count
              ) {
                buffer,
                  initializedCount in
                for (index, part) in parts.enumerated() {
                  let attributedString = NSAttributedString(
                    string: part.text,
                    attributes: [
                      .font: fontState.nsFontForDraw(for: part),
                      .foregroundColor: part.foregroundColor.appKit,
                    ]
                  )
                  buffer
                    .initializeElement(at: index, to: CTLineCreateWithAttributedString(
                      attributedString
                    ))
                }
                initializedCount = parts.count
              }
              return (chunkIndex, lines)
            }
          }

        var chunks = [[CTLine]?](repeating: nil, count: partsChunks.count)
        for await (chunkIndex, lines) in taskGroup {
          chunks[chunkIndex] = lines
        }

        return chunks
      }

      self.ioSurface.lock(seed: nil)

      self.cgContext.setShouldAntialias(false)
      for part in gridDrawRequest.parts {
        let frame = IntegerRectangle(
          origin: .init(column: part.columnsRange.lowerBound, row: part.row),
          size: .init(columnsCount: part.columnsRange.count, rowsCount: 1)
        )
        self.cgContext.setFillColor(part.backgroundColor.cg)
        self.cgContext.fill(frame * fontState.cellSize * self.contentsScale)
      }

      self.cgContext.setShouldAntialias(true)
      for (index, part) in gridDrawRequest.parts.enumerated() {
        self.cgContext.saveGState()

        let (quotient, remainder) = index.quotientAndRemainder(dividingBy: chunkSize)
        let line = chunks[quotient]![remainder]

        self.cgContext.textPosition = .init(
          x: Double(part.columnsRange.lowerBound) * fontState.cellSize.width,
          y: Double(
            part.row
          ) * fontState.cellSize.height - fontState.regular.boundingRectForFont.origin.y
        )
        self.cgContext.scaleBy(x: self.contentsScale, y: self.contentsScale)
        CTLineDraw(line, self.cgContext)

        self.cgContext.restoreGState()
      }

      self.cgContext.flush()

      self.ioSurface.unlock(seed: nil)

      cb()
    }
  }
}
