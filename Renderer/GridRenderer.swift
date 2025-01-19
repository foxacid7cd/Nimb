// SPDX-License-Identifier: MIT

import Algorithms
import AppKit
@preconcurrency import CoreText
import CustomDump
import IOSurface

@MainActor
public final class GridRenderer: @unchecked Sendable {
  public let gridID: Int

  private let globalState: RendererGlobalState
  private var font: NSFont?
  private var fontState: FontState?
  private var contentsScale: Double?
  private var layout: GridLayout?
  private var ioSurface: IOSurface?
  private var cgContext: CGContext?

  private var gridSize: IntegerSize? {
    layout?.size
  }

  private var cellSize: CGSize? {
    fontState?.cellSize
  }

  private var appearance: Appearance {
    globalState.appearance
  }

  public init(
    gridID: Int,
    globalState: RendererGlobalState
  ) {
    self.gridID = gridID
    self.globalState = globalState
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
    var newIOSurface: IOSurface?

    for renderOperation in renderOperations.array {
      switch renderOperation.type {
      case .resize:
        let resizeOperation = renderOperation.resize!

        font = resizeOperation.font
        fontState = .init(resizeOperation.font)
        contentsScale = resizeOperation.contentsScale

        if let layout {
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
          layout = .init(
            cells: .init(
              size: resizeOperation.size,
              repeatingElement: .default
            )
          )
        }

        let ioSurfaceSize = gridSize! * fontState!.cellSize * contentsScale!

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

            layout!.cells
              .rows[part.row]
              .replaceSubrange(
                part.colStart ..< part.colStart + cells.count,
                with: cells
              )

          } catch {
            logger.error("failed to handle line \(error)")
          }

          dirtyRows.insert(part.row)
        }

        ioSurface!.lock(seed: nil)

        for dirtyRow in dirtyRows {
          layout!
            .rowLayouts[dirtyRow] = RowLayout(
              rowCells: layout!.cells.rows[dirtyRow]
            )

          let flippedDirtyRow = gridSize!.rowsCount - dirtyRow - 1

          cgContext!.setShouldAntialias(false)
          for part in layout!.rowLayouts[dirtyRow].parts {
            let frame = IntegerRectangle(
              origin: .init(
                column: part.columnsRange.lowerBound,
                row: flippedDirtyRow
              ),
              size: .init(columnsCount: part.columnsRange.count, rowsCount: 1)
            )
            cgContext!
              .setFillColor(appearance.backgroundColor(for: part.highlightID).cg)
            cgContext!.fill(frame * fontState!.cellSize * contentsScale!)
          }

          cgContext!.setShouldAntialias(true)
          for part in layout!.rowLayouts[dirtyRow].parts {
            cgContext!.saveGState()

            let attributedString = NSAttributedString(
              string: part.text,
              attributes: [
                .font: fontState!.regular,
                .foregroundColor: appearance.foregroundColor(for: part.highlightID).appKit,
              ]
            )
            let ctLine = CTLineCreateWithAttributedString(
              attributedString
            )

            cgContext!.textPosition = .init(
              x: Double(part.columnsRange.lowerBound) * fontState!.cellSize.width,
              y: Double(
                flippedDirtyRow
              ) * fontState!.cellSize.height - fontState!.regular.boundingRectForFont.origin.y
            )
            cgContext!.scaleBy(x: contentsScale!, y: contentsScale!)
            CTLineDraw(ctLine, cgContext!)

            cgContext!.restoreGState()
          }

          cgContext!.flush()

          ioSurface!.unlock(seed: nil)
        }

      case .scroll:
        let scrollOperation = renderOperation.scroll!

        let cellsCopy = layout!.cells
        let rowLayoutsCopy = layout!.rowLayouts

        let toRectangle = scrollOperation.rectangle
          .applying(offset: -scrollOperation.offset)
          .intersection(with: scrollOperation.rectangle)

        for toRow in toRectangle.rows {
          let fromRow = toRow + scrollOperation.offset.rowsCount

          if scrollOperation.rectangle.size.columnsCount == layout!.size.columnsCount {
            layout!.cells.rows[toRow] = cellsCopy.rows[fromRow]
            layout!.rowLayouts[toRow] = rowLayoutsCopy[fromRow]
          } else {
            layout!.cells.rows[toRow].replaceSubrange(
              scrollOperation.rectangle.columns,
              with: cellsCopy.rows[fromRow][scrollOperation.rectangle.columns]
            )
            layout!.rowLayouts[toRow] = .init(rowCells: layout!.cells.rows[toRow])
          }
        }

        ioSurface!.lock(seed: nil)

        cgContext!.saveGState()

        let image = cgContext!.makeImage()!

        cgContext!.clip(
          to: [
            IntegerRectangle(
              origin: .init(
                column: toRectangle.origin.column,
                row: layout!.cells.size.rowsCount - toRectangle.size.rowsCount - toRectangle.origin.row
              ),
              size: toRectangle.size
            ) * cellSize! * contentsScale!,
          ]
        )

        cgContext!
          .draw(
            image,
            in: .init(
              origin: .init(
                column: scrollOperation.offset.columnsCount,
                row: scrollOperation.offset.rowsCount
              ) * cellSize! * contentsScale!,
              size: .init(width: image.width, height: image.height)
            )
          )

        cgContext!.restoreGState()

        cgContext!.flush()

        ioSurface!.unlock(seed: nil)
      }
    }

    cb(.init(isIOSurfaceUpdated: newIOSurface != nil, ioSurface: newIOSurface))
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
