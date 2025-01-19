// SPDX-License-Identifier: MIT

import Algorithms
import AppKit
@preconcurrency import CoreText
import CustomDump
import IOSurface
import Queue

public final class GridRenderer: @unchecked Sendable {
  public let gridID: Int

  private var font: NSFont?
  private var fontState: FontState?
  private var contentsScale: Double?
  private var layout: GridLayout?
  private var ioSurface: IOSurface?
  private var cgContext: CGContext?
  private let asyncQueue = AsyncQueue()

  private var gridSize: IntegerSize? {
    layout?.size
  }

  private var cellSize: CGSize? {
    fontState?.cellSize
  }

  public init(
    gridID: Int
  ) {
    self.gridID = gridID
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

  public func execute(
    renderOperations: GridRenderOperations,
    _ cb: @Sendable @escaping (_ result: GridRenderOperationsResult) -> Void
  ) {
    asyncQueue.addOperation {
      var newIOSurface: IOSurface?

      for renderOperation in renderOperations.array {
        switch renderOperation.type {
        case .resize:
          let resizeOperation = renderOperation.resize!

          self.font = resizeOperation.font
          self.fontState = .init(resizeOperation.font)
          self.contentsScale = resizeOperation.contentsScale

          if let layout = self.layout {
            if layout.size != resizeOperation.size {
              self.layout = .init(
                cells: .init(size: resizeOperation.size, elementAtPoint: { point in
                  if IntegerRectangle(size: layout.size).contains(point) {
                    layout.cells[point]
                  } else {
                    .default
                  }
                })
              )
              self.layout!.rowLayouts = (0 ..< resizeOperation.size.rowsCount)
                .map { row in
                  RowLayout(rowCells: self.layout!.cells.rows[row])
                }
            }
          } else {
            self.layout = .init(
              cells: .init(
                size: resizeOperation.size,
                repeatingElement: .default
              )
            )
          }

          let ioSurfaceSize = self.gridSize! * self.fontState!.cellSize * self.contentsScale!

          let ioSurface = IOSurface(
            properties: [
              .width: ioSurfaceSize.width,
              .height: ioSurfaceSize.height,
              .bytesPerElement: 4,
              .pixelFormat: kCVPixelFormatType_32BGRA,
            ]
          )!
          newIOSurface = ioSurface
          let cgContext = Self.makeCGContext(ioSurface: ioSurface)

          if let oldIOSurface = self.ioSurface, let oldCGContext = self.cgContext {
            oldIOSurface.lock(seed: nil)
            ioSurface.lock(seed: nil)

            cgContext
              .draw(
                oldCGContext.makeImage()!,
                in: .init(
                  origin: .zero,
                  size: .init(
                    width: ioSurface.width,
                    height: ioSurface.height
                  )
                )
              )

            cgContext.flush()

            oldIOSurface.unlock(seed: nil)
            ioSurface.unlock(seed: nil)
          }

          self.ioSurface = ioSurface
          self.cgContext = cgContext

        case .draw:
          var dirtyRows = Set<Int>()

          let drawOperationParts = renderOperation.draw!

          for part in drawOperationParts {
            do {
              var cells = [Cell]()
              var highlightID = 0

              for value in part.data {
                guard
                  case let .array(arrayValue) = value,
                  !arrayValue.isEmpty,
                  case let .string(text) = arrayValue[0]
                else {
                  throw Failure("invalid grid line cell value", value)
                }

                var repeatCount = 1

                if arrayValue.count > 1 {
                  guard
                    case let .integer(newHighlightID) = arrayValue[1]
                  else {
                    throw Failure(
                      "invalid grid line cell highlight value",
                      arrayValue[1]
                    )
                  }

                  highlightID = newHighlightID

                  if arrayValue.count > 2 {
                    guard
                      case let .integer(newRepeatCount) = arrayValue[2]
                    else {
                      throw Failure(
                        "invalid grid line cell repeat count value",
                        arrayValue[2]
                      )
                    }

                    repeatCount = newRepeatCount
                  }
                }

                let cell = Cell(text: text, highlightID: highlightID)
                for _ in 0 ..< repeatCount {
                  cells.append(cell)
                }
              }

              self.layout!.cells
                .rows[part.row]
                .replaceSubrange(
                  part.colStart ..< part.colStart + cells.count,
                  with: cells
                )

              //      self.layout!.cells.rows[part.row].replaceSubrange(
              //        part.originColumn ..< part.originColumn + cells.count,
              //        with: cells
              //      )
              //      self.layout!.rowLayouts[part.row] = RowLayout(rowCells: self.layout!.cells.rows[part.row])
              //
              //      dirtyRows.insert(part.row)
              //              redraw(dirtyRows: [part.row])

            } catch {
              logger.error("failed to handle line \(error)")
            }

            dirtyRows.insert(part.row)
          }

          self.ioSurface!.lock(seed: nil)

          for dirtyRow in dirtyRows {
            self.layout!
              .rowLayouts[dirtyRow] = RowLayout(
                rowCells: self.layout!.cells.rows[dirtyRow]
              )

            let flippedDirtyRow = self.gridSize!.rowsCount - dirtyRow - 1

            self.cgContext!.setShouldAntialias(false)
            for part in self.layout!.rowLayouts[dirtyRow].parts {
              let frame = IntegerRectangle(
                origin: .init(
                  column: part.columnsRange.lowerBound,
                  row: flippedDirtyRow
                ),
                size: .init(columnsCount: part.columnsRange.count, rowsCount: 1)
              )
              self.cgContext!.setFillColor(NSColor.black.cgColor)
              self.cgContext!.fill(frame * self.fontState!.cellSize * self.contentsScale!)
            }

            self.cgContext!.setShouldAntialias(true)
            for part in self.layout!.rowLayouts[dirtyRow].parts {
              self.cgContext!.saveGState()

              let attributedString = NSAttributedString(
                string: part.text,
                attributes: [
                  .font: self.fontState!.regular,
                  .foregroundColor: NSColor.white,
                ]
              )
              let ctLine = CTLineCreateWithAttributedString(
                attributedString
              )

              self.cgContext!.textPosition = .init(
                x: Double(part.columnsRange.lowerBound) * self.fontState!.cellSize.width,
                y: Double(
                  flippedDirtyRow
                ) * self.fontState!.cellSize.height - self.fontState!.regular.boundingRectForFont.origin.y
              )
              self.cgContext!.scaleBy(x: self.contentsScale!, y: self.contentsScale!)
              CTLineDraw(ctLine, self.cgContext!)

              self.cgContext!.restoreGState()
            }

            self.cgContext!.flush()

            self.ioSurface!.unlock(seed: nil)
          }

        case .scroll:
          let scrollOperation = renderOperation.scroll!

          let cellsCopy = self.layout!.cells
          let rowLayoutsCopy = self.layout!.rowLayouts

          let toRectangle = scrollOperation.rectangle
            .applying(offset: -scrollOperation.offset)
            .intersection(with: scrollOperation.rectangle)

          for toRow in toRectangle.rows {
            let fromRow = toRow + scrollOperation.offset.rowsCount

            if scrollOperation.rectangle.size.columnsCount == self.layout!.size.columnsCount {
              self.layout!.cells.rows[toRow] = cellsCopy.rows[fromRow]
              self.layout!.rowLayouts[toRow] = rowLayoutsCopy[fromRow]
            } else {
              self.layout!.cells.rows[toRow].replaceSubrange(
                scrollOperation.rectangle.columns,
                with: cellsCopy.rows[fromRow][scrollOperation.rectangle.columns]
              )
              self.layout!.rowLayouts[toRow] = .init(rowCells: self.layout!.cells.rows[toRow])
            }
          }

          self.ioSurface!.lock(seed: nil)

          self.cgContext!.saveGState()

          let image = self.cgContext!.makeImage()!

          self.cgContext!.clip(
            to: [
              IntegerRectangle(
                origin: .init(
                  column: toRectangle.origin.column,
                  row: self.layout!.cells.size.rowsCount - toRectangle.size.rowsCount - toRectangle.origin.row
                ),
                size: toRectangle.size
              ) * self.cellSize! * self.contentsScale!,
            ]
          )

          self.cgContext!
            .draw(
              image,
              in: .init(
                origin: .init(
                  column: scrollOperation.offset.columnsCount,
                  row: scrollOperation.offset.rowsCount
                ) * self.cellSize! * self.contentsScale!,
                size: .init(width: image.width, height: image.height)
              )
            )

          self.cgContext!.restoreGState()

          self.cgContext!.flush()

          self.ioSurface!.unlock(seed: nil)
        }
      }

      cb(.init(isIOSurfaceUpdated: newIOSurface != nil, ioSurface: newIOSurface))
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
