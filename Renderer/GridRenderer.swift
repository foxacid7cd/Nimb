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
  private var layout: GridLayout?

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
      if let layout = self.layout {
        if layout.size != gridContext.size {
          self.layout = .init(
            cells: .init(size: gridContext.size, elementAtPoint: { point in
              if IntegerRectangle(size: layout.size).contains(point) {
                layout.cells[point]
              } else {
                .default
              }
            })
          )
          self.layout!.rowLayouts = (0 ..< gridContext.size.rowsCount).map { row in
            RowLayout(rowCells: self.layout!.cells.rows[row])
          }
        }
      } else {
        self.layout = .init(
          cells: .init(size: gridContext.size, repeatingElement: .default)
        )
      }

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

  public func execute(renderOperations: GridRenderOperations, _ cb: @Sendable @escaping () -> Void) {
    asyncQueue.addOperation {
      let fontState = self.fontState

      self.ioSurface.lock(seed: nil)

      if self.layout == nil {
        self.layout = .init(
          cells: .init(size: self.gridSize, repeatingElement: .default)
        )
      }

      for renderOperation in renderOperations.array {
        switch renderOperation.type {
        case .draw:
          var dirtyRows = Set<Int>()

          let drawOperationParts = renderOperation.draw!

          for part in drawOperationParts {
            self.layout!.cells.rows[part.row] = part.cells
            self.layout!.rowLayouts[part.row] = RowLayout(rowCells: self.layout!.cells.rows[part.row])

            dirtyRows.insert(part.row)
//              redraw(dirtyRows: [part.row])
          }

          for dirtyRow in dirtyRows {
            self.cgContext.setShouldAntialias(false)
            for part in self.layout!.rowLayouts[dirtyRow].parts {
              let frame = IntegerRectangle(
                origin: .init(
                  column: part.columnsRange.lowerBound,
                  row: dirtyRow
                ),
                size: .init(columnsCount: part.columnsRange.count, rowsCount: 1)
              )
              self.cgContext.setFillColor(NSColor.black.cgColor)
              self.cgContext.fill(frame * fontState.cellSize * self.contentsScale)
            }

            self.cgContext.setShouldAntialias(true)
            for part in self.layout!.rowLayouts[dirtyRow].parts {
              self.cgContext.saveGState()

              let attributedString = NSAttributedString(
                string: part.text,
                attributes: [
                  .font: fontState.regular,
                  .foregroundColor: NSColor.white,
                ]
              )
              let ctLine = CTLineCreateWithAttributedString(
                attributedString
              )

              self.cgContext.textPosition = .init(
                x: Double(part.columnsRange.lowerBound) * fontState.cellSize.width,
                y: Double(
                  dirtyRow
                ) * fontState.cellSize.height - fontState.regular.boundingRectForFont.origin.y
              )
              self.cgContext.scaleBy(x: self.contentsScale, y: self.contentsScale)
              CTLineDraw(ctLine, self.cgContext)

              self.cgContext.restoreGState()
            }
          }

        case .scroll:
          let scrollOperation = renderOperation.scroll!

          self.cgContext.saveGState()

          let toRectangle = IntegerRectangle(
            origin: .init(
              column: scrollOperation.offset.columnsCount,
              row: scrollOperation.offset.rowsCount
            ),
            size: self.gridSize
          )
          .intersection(with: IntegerRectangle(size: self.gridSize))

          self.cgContext.clip(to: [
            toRectangle * self.cellSize * self.contentsScale,
          ])

          let image = self.cgContext.makeImage()!
          self.cgContext
            .draw(
              image,
              in: .init(
                origin: .init(
                  column: scrollOperation.offset.columnsCount,
                  row: scrollOperation.offset.rowsCount
                ) * self.cellSize * self.contentsScale,
                size: .init(width: image.width, height: image.height)
              )
            )

          self.cgContext.restoreGState()
        }
      }

      self.cgContext.flush()

      self.ioSurface.unlock(seed: nil)

      cb()
    }
  }

//  public func draw(
//    operation: GridRenderDrawOperation,
//    _ cb: @Sendable @escaping () -> Void
//  ) {
//    asyncQueue.addOperation {
//      let fontState = self.fontState
//
//      let chunks = await withTaskGroup(of: (chunkIndex: Int, lines: [CTLine]).self) { taskGroup in
//        let partsChunks = gridDrawRequest.parts
//          .chunks(ofCount: chunkSize)
//
//        partsChunks
//          .enumerated()
//          .forEach { chunkIndex, parts in
//            taskGroup.addTask {
//              let lines = [CTLine](
//                unsafeUninitializedCapacity: parts.count
//              ) {
//                buffer,
//                  initializedCount in
//                for (index, part) in parts.enumerated() {
//                  let attributedString = NSAttributedString(
//                    string: part.text,
//                    attributes: [
//                      .font: fontState.nsFontForDraw(for: part),
//                      .foregroundColor: part.foregroundColor.appKit,
//                    ]
//                  )
//                  buffer
//                    .initializeElement(at: index, to: CTLineCreateWithAttributedString(
//                      attributedString
//                    ))
//                }
//                initializedCount = parts.count
//              }
//              return (chunkIndex, lines)
//            }
//          }
//
//        var chunks = [[CTLine]?](repeating: nil, count: partsChunks.count)
//        for await (chunkIndex, lines) in taskGroup {
//          chunks[chunkIndex] = lines
//        }
//
//        return chunks
//      }
//
//      self.ioSurface.lock(seed: nil)
//
//      self.cgContext.setShouldAntialias(false)
//      for part in operation.parts {
//        let frame = IntegerRectangle(
//          origin: .init(column: part.columnsRange.lowerBound, row: part.row),
//          size: .init(columnsCount: part.columnsRange.count, rowsCount: 1)
//        )
//        self.cgContext.setFillColor(part.backgroundColor.cg)
//        self.cgContext.fill(frame * fontState.cellSize * self.contentsScale)
//      }
//
//      self.cgContext.setShouldAntialias(true)
//      for (index, part) in operation.parts.enumerated() {
//        self.cgContext.saveGState()
//
//        let (quotient, remainder) = index.quotientAndRemainder(dividingBy: chunkSize)
//        let line = chunks[quotient]![remainder]
//
//        self.cgContext.textPosition = .init(
//          x: Double(part.columnsRange.lowerBound) * fontState.cellSize.width,
//          y: Double(
//            part.row
//          ) * fontState.cellSize.height - fontState.regular.boundingRectForFont.origin.y
//        )
//        self.cgContext.scaleBy(x: self.contentsScale, y: self.contentsScale)
//        CTLineDraw(line, self.cgContext)
//
//        self.cgContext.restoreGState()
//      }
//
//      self.cgContext.flush()
//
//      self.ioSurface.unlock(seed: nil)
//
//      cb()
//    }
//  }
//
//  public func scroll(
//    operation: GridRenderScrollOperation,
//    _ cb: @Sendable @escaping () -> Void
//  ) {
//    asyncQueue.addOperation {
//      self.ioSurface.lock(seed: nil)
//
//      let image = self.cgContext.makeImage()!
//      self.cgContext
//        .draw(
//          image,
//          in: .init(
//            origin: .init(
//              column: operation.offset.columnsCount,
//              row: operation.offset.rowsCount
//            ) * self.cellSize * self.contentsScale,
//            size: .init(width: image.width, height: image.height)
//          )
//        )
//
//      self.cgContext.flush()
//
//      self.ioSurface.unlock(seed: nil)
//
//      cb()
//    }
//  }
}
