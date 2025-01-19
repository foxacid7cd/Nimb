// SPDX-License-Identifier: MIT

import Algorithms
import AppKit
import Collections
import ConcurrencyExtras
import CoreImage
import CoreMedia
import CustomDump
@preconcurrency import IOSurface
import Queue

public class GridLayer: CALayer, @unchecked Sendable {
  public enum AssociatedWindow: Sendable {
    case plain(Window)
    case floating(FloatingWindow)
    case external(ExternalWindow)
  }

  private class SurfaceLayer: CALayer {
    override func action(forKey event: String) -> (any CAAction)? {
      NSNull()
    }

    override func hitTest(_: CGPoint) -> CALayer? {
      nil
    }
  }

  override public var contentsScale: CGFloat {
    didSet {
      surfaceLayer.contentsScale = contentsScale
    }
  }

  public var font: Font?

  public var associatedWindow: AssociatedWindow?

  @MainActor
  public var lastHandledGridSize: IntegerSize?

  let gridID: Grid.ID

  private let store: Store
  private let remoteRenderer: RendererProtocol
  private let surfaceLayer = SurfaceLayer()
  private var ioSurface: IOSurface?
  @MainActor
  private var isScrollingHorizontal: Bool?
  @MainActor
  private var xScrollingAccumulator: Double = 0
  @MainActor
  private var xScrollingReported: Double = 0
  @MainActor
  private var yScrollingAccumulator: Double = 0
  @MainActor
  private var yScrollingReported: Double = 0
  private var previousMouseMove: (modifier: String, point: IntegerPoint)?
  private var previousGridSize = IntegerSize(columnsCount: 0, rowsCount: 0)
  private var previousCursorRow: Int?
  private let rendererQueue: AsyncQueue
  private var pendingRenderOperations = [GridRenderOperation]()
  private var gridSize: IntegerSize?

  @MainActor
  private var upsideDownTransform: CGAffineTransform {
    guard let font, let gridSize else {
      return .identity
    }
    return .init(scaleX: 1, y: -1)
      .translatedBy(x: 0, y: -Double(gridSize.rowsCount) * font.cellHeight)
  }

  override public init(layer: Any) {
    let gridLayer = layer as! GridLayer

    store = gridLayer.store
    remoteRenderer = gridLayer.remoteRenderer
    gridID = gridLayer.gridID

    rendererQueue = .init()

    super.init(layer: layer)
  }

  @MainActor
  init(
    store: Store,
    remoteRenderer: RendererProtocol,
    gridID: Grid.ID,
    rendererQueue: AsyncQueue = .init()
  ) {
    self.store = store
    self.remoteRenderer = remoteRenderer
    self.gridID = gridID
    self.rendererQueue = rendererQueue

    super.init()

    isOpaque = false
    masksToBounds = true
    backgroundColor = NSColor.red.withAlphaComponent(0.05).cgColor

    surfaceLayer.contentsGravity = .bottomLeft
    surfaceLayer.isOpaque = false
    surfaceLayer.contentsScale = contentsScale
    addSublayer(surfaceLayer)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func action(forKey event: String) -> (any CAAction)? {
    NSNull()
  }

//  @MainActor
//  public func createNewIOSurface() {
//    guard let font, let gridSize else {
//      return
//    }
//    let size = gridSize * font.cellSize * contentsScale
//
//    let ioSurface = IOSurface(
//      properties: [
//        .width: size.width,
//        .height: size.height,
//        .bytesPerElement: 4,
//        .pixelFormat: kCVPixelFormatType_32BGRA,
//      ]
//    )!
//    self.ioSurface = ioSurface
//    surfaceLayer.contents = ioSurface
//    surfaceLayer.frame = .init(
//      origin: .zero,
//      size: gridSize * font.cellSize
//    )
//  }

  //  override public func draw(in ctx: CGContext) {
  //    guard let critical = critical.withValue({ $0 }) else {
  //      return
  //    }
  //
  //    let boundingRect = IntegerRectangle(
  //      frame: ctx.boundingBoxOfClipPath.applying(critical.upsideDownTransform),
  //      cellSize: critical.font.cellSize
  //    )
  //
  //    ctx.setShouldAntialias(false)
  //    critical.grid.drawRuns.drawBackground(
  //      to: ctx,
  //      boundingRect: boundingRect,
  //      font: critical.font,
  //      appearance: critical.appearance,
  //      upsideDownTransform: critical.upsideDownTransform
  //    )
  //
  //    ctx.setShouldAntialias(true)
  //    critical.grid.drawRuns.drawForeground(
  //      to: ctx,
  //      boundingRect: boundingRect,
  //      font: critical.font,
  //      appearance: critical.appearance,
  //      upsideDownTransform: critical.upsideDownTransform
  //    )
  //
  //    if
  //      critical.cursorBlinkingPhase,
  //      critical.isMouseUserInteractionEnabled,
  //      let cursorDrawRun = critical.grid.drawRuns.cursorDrawRun,
  //      boundingRect.contains(cursorDrawRun.origin)
  //    {
  //      cursorDrawRun.draw(
  //        to: ctx,
  //        font: critical.font,
  //        appearance: critical.appearance,
  //        upsideDownTransform: critical.upsideDownTransform
  //      )
  //    }
  //  }

  @MainActor
  public func render() {
    //    if let layout {
    //      if grid.size != layout.size {
    //        let copyColumnsCount = min(layout.columnsCount, grid.size.columnsCount)
    //        let copyColumnsRange = 0 ..< copyColumnsCount
    //        let copyRowsCount = min(layout.rowsCount, grid.size.rowsCount)
    //        var cells = TwoDimensionalArray<Cell>(
    //          size: grid.size,
    //          repeatingElement: .default
    //        )
    //        for row in 0 ..< copyRowsCount {
    //          cells.rows[row].replaceSubrange(
    //            copyColumnsRange,
    //            with: layout.cells.rows[row][copyColumnsRange]
    //          )
    //        }
    //        self.layout = .init(cells: cells)
    //      }
    //    } else {
    //      layout = .init(cells: .init(size: grid.size, repeatingElement: .default))
    //    }
    //
    //    var gridUpdateResult: Grid.UpdateResult?
    //    if let gridUpdates = updates.gridUpdates[gridID] {
    //      for gridUpdate in gridUpdates {
    //        if let result = apply(update: gridUpdate) {
    //          if gridUpdateResult != nil {
    //            gridUpdateResult!.formUnion(result)
    //          } else {
    //            gridUpdateResult = result
    //          }
    //        }
    //      }
    //    }
    //
    //    var shouldRecreateIOSurface = false
    //
    //    if ioSurface == nil {
    //      createNewIOSurface()
    //      registerNewGridContext()
    //    } else {
    //      if updates.isFontUpdated {
    //        shouldRecreateIOSurface = true
    //      }
    //
    //      if
    //        updates.updatedLayoutGridIDs.contains(gridID),
    //        grid.size.columnsCount > previousGridSize.columnsCount || grid.size.rowsCount > previousGridSize.rowsCount
    //      {
    //        shouldRecreateIOSurface = true
    //      }
    //
    //      if shouldRecreateIOSurface {
    //        createNewIOSurface()
    //        registerNewGridContext()
    //      }
    //    }
    //
    //    let cursorRow = state.cursor?.gridID == gridID ? state.cursor?.position.row : nil
    //
    //    let dirtyRows = { () -> any Sequence<Int> in
    //      if
    //        updates.isFontUpdated || updates.isAppearanceUpdated || shouldRecreateIOSurface
    //      {
    //        return 0 ..< grid.rowsCount
    //      }
    //
    //      var accumulator = Set<Int>()
    //
    //      if let cursorRow, cursorRow != previousCursorRow {
    //        accumulator.insert(cursorRow)
    //        if let previousCursorRow {
    //          accumulator.insert(previousCursorRow)
    //        }
    //      } else if updates.isCursorBlinkingPhaseUpdated || updates.isMouseUserInteractionEnabledUpdated {
    //        if let cursorRow {
    //          accumulator.insert(cursorRow)
    //        }
    //        if let previousCursorRow {
    //          accumulator.insert(previousCursorRow)
    //        }
    //      }
    //
    //      if let gridUpdate = gridUpdateResult {
    //        switch gridUpdate {
    //        case let .dirtyRectangles(rectangles):
    //          for rectangle in rectangles {
    //            for row in rectangle.minRow ..< rectangle.maxRow {
    //              accumulator.insert(row)
    //            }
    //          }
    //
    //        case .needsDisplay:
    //          return 0 ..< grid.rowsCount
    //        }
    //      }
    //
    //      return accumulator
    //    }()
    //
    //    var drawRequestParts = [GridDrawRequestPart]()
    //    for dirtyRow in dirtyRows {
    //      let flippedDirtyRow = grid.rowsCount - dirtyRow - 1
    //      for part in layout!.rowLayouts[dirtyRow].parts {
    //        let decorations = state.appearance.decorations(for: part.highlightID)
    //
    //        drawRequestParts
    //          .append(
    //            .init(
    //              row: flippedDirtyRow,
    //              columnsRange: part.columnsRange,
    //              text: part.text,
    //              backgroundColor: state.appearance
    //                .backgroundColor(for: part.highlightID),
    //              foregroundColor: state.appearance.foregroundColor(
    //                for: part.highlightID
    //              ),
    //              isBold: state.appearance.isBold(for: part.highlightID),
    //              isItalic: state.appearance.isItalic(for: part.highlightID),
    //              isStrikethrough: decorations.isStrikethrough,
    //              isUnderline: decorations.isUnderline,
    //              isUndercurl: decorations.isUndercurl,
    //              isUnderdouble: decorations.isUnderdouble,
    //              isUnderdotted: decorations.isUnderdotted,
    //              isUnderdashed: decorations.isUnderdashed
    //            )
    //          )
    //
    //        if
    //          let cursor = state.cursor, cursor.gridID == gridID, cursor.position.row == dirtyRow, part.columnsRange
    //            .contains(cursor.position.column), state.cursorBlinkingPhase
    //        {
    //          var cell: RowPart.Cell?
    //          let currentColumn = part.columnsRange.startIndex
    //          for currentCell in part.cells {
    //            if
    //              (currentColumn + currentCell.columnsRange.lowerBound ..< currentColumn + currentCell.columnsRange.upperBound).contains(
    //                cursor.position.column
    //              )
    //            {
    //              cell = currentCell
    //              break
    //            }
    //          }
    //          drawRequestParts
    //            .append(
    //              .init(
    //                row: flippedDirtyRow,
    //                columnsRange: currentColumn + cell!.columnsRange.lowerBound ..< currentColumn + cell!.columnsRange.upperBound,
    //                text: String(part.text[cell!.textRange]),
    //                backgroundColor: state.appearance.foregroundColor(
    //                  for: part.highlightID
    //                ),
    //                foregroundColor: state.appearance
    //                  .backgroundColor(for: part.highlightID),
    //                isBold: state.appearance.isBold(for: part.highlightID),
    //                isItalic: state.appearance.isItalic(for: part.highlightID),
    //                isStrikethrough: decorations.isStrikethrough,
    //                isUnderline: decorations.isUnderline,
    //                isUndercurl: decorations.isUndercurl,
    //                isUnderdouble: decorations.isUnderdouble,
    //                isUnderdotted: decorations.isUnderdotted,
    //                isUnderdashed: decorations.isUnderdashed
    //              )
    //            )
    //        }
    //      }
    //    }
    //
    //    if !drawRequestParts.isEmpty {
    //      let remoteRenderer = remoteRenderer
    //      let gridID = gridID
    //
    //      rendererQueue.addOperation {
    //        await withUnsafeContinuation { continuation in
    //          remoteRenderer
    //            .draw(
    //              gridDrawRequest: .init(parts: drawRequestParts),
    //              forGridWithID: gridID,
    //              {
    //                continuation.resume()
    //              }
    //            )
    //        }
    //        Task { @MainActor in
    //          self.setNeedsDisplay()
    //        }
    //      }
    //    }
    //
    //    previousGridSize = grid.size
    //    previousCursorRow = cursorRow
  }

  @MainActor
  public func scrollWheel(with event: NSEvent) {
    //    guard
    //      state.isMouseUserInteractionEnabled,
    //      state.cmdlines.dictionary.isEmpty
    //    else {
    //      return
    //    }
    guard let font else {
      return
    }

    let scrollingSpeedMultiplier = 1.1
    let xThreshold = font.cellWidth * 8 * scrollingSpeedMultiplier
    let yThreshold = font.cellHeight * scrollingSpeedMultiplier

    if event.phase == .began {
      isScrollingHorizontal = nil
      xScrollingAccumulator = 0
      xScrollingReported = -xThreshold / 2
      yScrollingAccumulator = 0
      yScrollingReported = -yThreshold / 2
    }

    let momentumPhaseScrollingSpeedMultiplier =
      event.momentumPhase
        .rawValue == 0 ? 1 : 0.9
    xScrollingAccumulator -=
      event
      .scrollingDeltaX * momentumPhaseScrollingSpeedMultiplier
    yScrollingAccumulator -=
      event
      .scrollingDeltaY * momentumPhaseScrollingSpeedMultiplier

    let xScrollingDelta = xScrollingAccumulator - xScrollingReported
    let yScrollingDelta = yScrollingAccumulator - yScrollingReported

    var horizontalScrollCount = 0
    var verticalScrollCount = 0

    if abs(xScrollingDelta) > xThreshold {
      horizontalScrollCount = Int(xScrollingDelta / xThreshold)
      let xScrollingToBeReported = xThreshold * Double(horizontalScrollCount)

      xScrollingReported += xScrollingToBeReported
    }
    if abs(yScrollingDelta) > yThreshold {
      verticalScrollCount = Int(
        yScrollingDelta / yThreshold
      )
      let yScrollingToBeReported = yThreshold * Double(verticalScrollCount)

      yScrollingReported += yScrollingToBeReported
    }

    if horizontalScrollCount != 0 || verticalScrollCount != 0 {
      let modifier = event.modifierFlags.makeModifiers(isSpecialKey: false)
        .joined()
      let point = point(for: event)
      var horizontalScrollFunctions = [any APIFunction]().cycled(times: 0)
      if horizontalScrollCount != 0 {
        horizontalScrollFunctions = [
          APIFunctions.NvimInputMouse(
            button: "wheel",
            action: horizontalScrollCount < 0 ? "left" : "right",
            modifier: modifier,
            grid: gridID,
            row: point.row,
            col: point.column
          ),
        ].cycled(times: abs(horizontalScrollCount))
      }

      var verticalScrollFunctions = [any APIFunction]().cycled(times: 0)
      if verticalScrollCount != 0 {
        verticalScrollFunctions = [
          APIFunctions.NvimInputMouse(
            button: "wheel",
            action: verticalScrollCount < 0 ? "up" : "down",
            modifier: modifier,
            grid: gridID,
            row: point.row,
            col: point.column
          ),
        ].cycled(times: abs(verticalScrollCount))
      }

      do {
        try store.api
          .fastCallsTransaction(
            with: chain(horizontalScrollFunctions, verticalScrollFunctions)
          )
      } catch {
        store.show(alert: .init(error))
      }
    }
  }

  @MainActor
  public func reportMouseMove(for event: NSEvent) {
    //    guard
    //      state.isMouseUserInteractionEnabled,
    //      state.cmdlines.dictionary.isEmpty
    //    else {
    //      return
    //    }

    let mouseMove = (
      modifier: event.modifierFlags.makeModifiers(isSpecialKey: false).joined(),
      point: point(for: event)
    )
    if
      mouseMove.modifier == previousMouseMove?.modifier,
      mouseMove.point == previousMouseMove?.point
    {
      return
    }
    do {
      try store.api.fastCall(
        APIFunctions.NvimInputMouse(
          button: "move",
          action: "",
          modifier: mouseMove.modifier,
          grid: gridID,
          row: mouseMove.point.row,
          col: mouseMove.point.column
        )
      )
    } catch {
      store.show(alert: .init(error))
    }
    previousMouseMove = mouseMove
  }

  @MainActor
  public func point(for event: NSEvent) -> IntegerPoint {
    guard let font else {
      return .init()
    }
    let upsideDownLocation = convert(event.locationInWindow, from: nil)
      .applying(upsideDownTransform)
    return .init(
      column: Int(upsideDownLocation.x / font.cellWidth),
      row: Int(upsideDownLocation.y / font.cellHeight)
    )
  }

  @MainActor
  public func windowFrame(forGridFrame gridFrame: IntegerRectangle) -> CGRect {
    guard let font else {
      return .init()
    }
    let viewFrame = (gridFrame * font.cellSize)
      .applying(upsideDownTransform)
    return convert(viewFrame, to: nil)
  }

  @MainActor
  public func report(
    mouseButton: String,
    action: String,
    with event: NSEvent
  ) {
    //    guard state.isMouseUserInteractionEnabled else {
    //      return
    //    }
    let point = point(for: event)
    let modifier = event.modifierFlags.makeModifiers(isSpecialKey: false)
      .joined()
    store.apiTask { [gridID] in
      try await $0
        .nvimInputMouse(
          button: mouseButton,
          action: action,
          modifier: modifier,
          grid: gridID,
          row: point.row,
          col: point.column
        )
    }
  }

  public func handleResize(gridSize: IntegerSize) {
    self.gridSize = gridSize
    pendingRenderOperations
      .append(
        .init(
          type: .resize,
          resize: .init(
            font: font!.appKit(),
            contentsScale: contentsScale,
            size: gridSize
          )
        )
      )

//    if let layout {
//      if layout.cells.size != gridSize {
//        let copyColumnsCount = min(layout.columnsCount, gridSize.columnsCount)
//        let copyColumnsRange = 0 ..< copyColumnsCount
//        let copyRowsCount = min(layout.rowsCount, gridSize.rowsCount)
//        var cells = TwoDimensionalArray<Cell>(
//          size: gridSize,
//          repeatingElement: .default
//        )
//        for row in 0 ..< copyRowsCount {
//          cells.rows[row].replaceSubrange(
//            copyColumnsRange,
//            with: layout.cells.rows[row][copyColumnsRange]
//          )
//        }
//        self.layout = .init(cells: cells)
//        createNewIOSurface()
//        registerNewGridContext()
//      }
//    } else {
//      layout = .init(cells: .init(size: gridSize, repeatingElement: .default))
//      createNewIOSurface()
//      registerNewGridContext()
//    }
  }

  public func handleLine(row: Int, originColumn: Int, data: [Value], wrap: Bool) {
    if case .draw = pendingRenderOperations.last?.type {
      pendingRenderOperations[pendingRenderOperations.count - 1].draw!
        .append(.init(row: row, colStart: originColumn, data: data, wrap: wrap))

    } else {
      pendingRenderOperations
        .append(
          .init(
            type: .draw,
            draw: [.init(row: row, colStart: originColumn, data: data, wrap: wrap)]
          )
        )
    }

//    do {
//      var cells = [Cell]()
//      var highlightID = 0
//
//      for value in data {
//        guard
//          case let .array(arrayValue) = value,
//          !arrayValue.isEmpty,
//          case let .string(text) = arrayValue[0]
//        else {
//          throw Failure("invalid grid line cell value", value)
//        }
//
//        var repeatCount = 1
//
//        if arrayValue.count > 1 {
//          guard
//            case let .integer(newHighlightID) = arrayValue[1]
//          else {
//            throw Failure(
//              "invalid grid line cell highlight value",
//              arrayValue[1]
//            )
//          }
//
//          highlightID = newHighlightID
//
//          if arrayValue.count > 2 {
//            guard
//              case let .integer(newRepeatCount) = arrayValue[2]
//            else {
//              throw Failure(
//                "invalid grid line cell repeat count value",
//                arrayValue[2]
//              )
//            }
//
//            repeatCount = newRepeatCount
//          }
//        }
//
//        let cell = Cell(text: text, highlightID: highlightID)
//        for _ in 0 ..< repeatCount {
//          cells.append(cell)
//        }
//      }
//
//      layout!.cells.rows[row].replaceSubrange(
//        originColumn ..< originColumn + cells.count,
//        with: cells
//      )
//      layout!.rowLayouts[row] = RowLayout(rowCells: layout!.cells.rows[row])
//
//    } catch {
//      logger.error("failed to handle line \(error)")
//    }
  }

  public func handleScroll(rectangle: IntegerRectangle, offset: IntegerSize) {
    pendingRenderOperations
      .append(
        .init(type: .scroll, scroll: .init(rectangle: rectangle, offset: offset))
      )

//    guard var layout, let gridSize else {
//      return
//    }
//
//    if offset.columnsCount != 0 {
//      logger.fault("horizontal scroll not supported!!!")
//    }
//
//    let cellsCopy = layout.cells
//    let rowLayoutsCopy = layout.rowLayouts
//
//    let toRectangle = rectangle
//      .applying(offset: -offset)
//      .intersection(with: rectangle)
//
//    for toRow in toRectangle.rows {
//      let fromRow = toRow + offset.rowsCount
//
//      if rectangle.size.columnsCount == gridSize.columnsCount {
//        layout.cells.rows[toRow] = cellsCopy.rows[fromRow]
//        layout.rowLayouts[toRow] = rowLayoutsCopy[fromRow]
//      } else {
//        layout.cells.rows[toRow].replaceSubrange(
//          rectangle.columns,
//          with: cellsCopy.rows[fromRow][rectangle.columns]
//        )
//        layout.rowLayouts[toRow] = .init(rowCells: layout.cells.rows[toRow])
//      }
//    }
//
//    self.layout = layout

    //    rendererQueue.addOperation {
    //      await withUnsafeContinuation { continuation in
    //        self.remoteRenderer
    //          .scroll(
    //            gridScrollRequest: .init(rectangle: rectangle, offset: offset),
    //            forGridWithID: self.gridID,
    //            {
    //              continuation.resume()
    //            }
    //          )
    //      }
    //      Task { @MainActor in
    //        self.setNeedsDisplay()
    //      }
    //    }
  }

  public func handleClear() {
//    pendingRenderOperations
//      .append(.clear)

//    guard var layout else {
//      return
//    }
//    layout.cells = .init(size: layout.cells.size, repeatingElement: .default)
//    layout.rowLayouts = layout.cells.rows
//      .map(RowLayout.init(rowCells:))
//    self.layout = layout
//
//    redraw(dirtyRows: 0 ..< layout.cells.size.rowsCount)
  }

  public func handleFlush() {
    guard !pendingRenderOperations.isEmpty else {
      return
    }

    let renderOperations = GridRenderOperations(array: pendingRenderOperations)
    pendingRenderOperations.removeAll(keepingCapacity: true)

    rendererQueue.addOperation {
      let result = await withUnsafeContinuation { continuation in
        self.remoteRenderer
          .execute(
            renderOperations: renderOperations,
            forGridWithID: self.gridID
          ) { result in
            continuation.resume(returning: result)
          }
      }
      Task { @MainActor in
        if result.isIOSurfaceUpdated {
          self.surfaceLayer.contents = result.ioSurface!
          self.surfaceLayer.frame = .init(
            origin: .zero,
            size: .init(
              width: Double(result.ioSurface!.width) / self.contentsScale,
              height: Double(result.ioSurface!.height) / self.contentsScale
            )
          )
        }
        self.setNeedsDisplay()
      }
    }
  }

//  @MainActor
//  private func redraw(dirtyRows: any Sequence<Int>) {
//    guard let gridSize, let layout else {
//      return
//    }
//
//    let renderOperationsContinuation = renderOperationsContinuation
//
//    var drawOperationParts = [GridRenderDrawOperationPart]()
//
//    for dirtyRow in dirtyRows {
//      let flippedDirtyRow = gridSize.rowsCount - dirtyRow - 1
//      for part in layout.rowLayouts[dirtyRow].parts {
//        //            let decorations = state.appearance.decorations(for: part.highlightID)
//
//        drawOperationParts
//          .append(
//            .init(
//              row: flippedDirtyRow,
//              columnsRange: part.columnsRange,
//              text: part.text,
//              backgroundColor: Color.black,
//              foregroundColor: Color.white,
//              isBold: false,
//              isItalic: false,
//              isStrikethrough: false,
//              isUnderline: false,
//              isUndercurl: false,
//              isUnderdouble: false,
//              isUnderdotted: false,
//              isUnderdashed: false
//            )
//          )

  //            if
  //              let cursor = state.cursor, cursor.gridID == gridID, cursor.position.row == dirtyRow, part.columnsRange
  //                .contains(cursor.position.column), state.cursorBlinkingPhase
  //            {
  //              var cell: RowPart.Cell?
  //              let currentColumn = part.columnsRange.startIndex
  //              for currentCell in part.cells {
  //                if
  //                  (currentColumn + currentCell.columnsRange.lowerBound ..< currentColumn + currentCell.columnsRange.upperBound).contains(
  //                    cursor.position.column
  //                  )
  //                {
  //                  cell = currentCell
  //                  break
  //                }
  //              }
  //              drawRequestParts
  //                .append(
  //                  .init(
  //                    row: flippedDirtyRow,
  //                    columnsRange: currentColumn + cell!.columnsRange.lowerBound ..< currentColumn + cell!.columnsRange.upperBound,
  //                    text: String(part.text[cell!.textRange]),
  //                    backgroundColor: state.appearance.foregroundColor(
  //                      for: part.highlightID
  //                    ),
  //                    foregroundColor: state.appearance
  //                      .backgroundColor(for: part.highlightID),
  //                    isBold: state.appearance.isBold(for: part.highlightID),
  //                    isItalic: state.appearance.isItalic(for: part.highlightID),
  //                    isStrikethrough: decorations.isStrikethrough,
  //                    isUnderline: decorations.isUnderline,
  //                    isUndercurl: decorations.isUndercurl,
  //                    isUnderdouble: decorations.isUnderdouble,
  //                    isUnderdotted: decorations.isUnderdotted,
  //                    isUnderdashed: decorations.isUnderdashed
  //                  )
  //                )
  //            }
}

//      _ = renderOperationsContinuation
//        .yield([.init(type: .draw, draw: drawOperationParts, scroll: nil)])

//    if !drawRequestParts.isEmpty {
//      let remoteRenderer = remoteRenderer
//      let gridID = gridID
//
//      rendererQueue.addOperation {
//        await withUnsafeContinuation { continuation in
//          remoteRenderer
//            .draw(
//              gridDrawRequest: .init(parts: drawRequestParts),
//              forGridWithID: gridID,
//              {
//                continuation.resume()
//              }
//            )
//        }
//        Task { @MainActor in
//          self.setNeedsDisplay()
//        }
//      }
//    }

//
//  @MainActor
//  private func apply(
//    update: Grid.Update
//  )
//    -> Grid.UpdateResult?
//  {
//    switch update {
//    case let .resize(integerSize):
//      let copyColumnsCount = min(layout!.columnsCount, integerSize.columnsCount)
//      let copyColumnsRange = 0 ..< copyColumnsCount
//      let copyRowsCount = min(layout!.rowsCount, integerSize.rowsCount)
//      var cells = TwoDimensionalArray<Cell>(
//        size: integerSize,
//        repeatingElement: .default
//      )
//      for row in 0 ..< copyRowsCount {
//        cells.rows[row].replaceSubrange(
//          copyColumnsRange,
//          with: layout!.cells.rows[row][copyColumnsRange]
//        )
//      }
//      layout = .init(cells: cells)
//
//      return .needsDisplay
//
//    case let .line(row, originColumn, cells):
//      layout!.cells.rows[row].replaceSubrange(
//        originColumn ..< originColumn + cells.count,
//        with: cells
//      )
//      layout!.rowLayouts[row] = RowLayout(rowCells: layout!.cells.rows[row])
//      return .dirtyRectangles([.init(
//        origin: .init(column: originColumn, row: row),
//        size: .init(columnsCount: cells.count, rowsCount: 1)
//      )])
//
//    case let .scroll(rectangle, offset):
//      if offset.columnsCount != 0 {
//        Task { @MainActor in
//          logger.error("horizontal scroll not supported!!!")
//        }
//      }
//
//      let cellsCopy = layout!.cells
//      let rowLayoutsCopy = layout!.rowLayouts
//
//      let toRectangle = rectangle
//        .applying(offset: -offset)
//        .intersection(with: rectangle)
//
//      for toRow in toRectangle.rows {
//        let fromRow = toRow + offset.rowsCount
//
//        if rectangle.size.columnsCount == grid.size.columnsCount {
//          layout!.cells.rows[toRow] = cellsCopy.rows[fromRow]
//          layout!.rowLayouts[toRow] = rowLayoutsCopy[fromRow]
//        } else {
//          layout!.cells.rows[toRow].replaceSubrange(
//            rectangle.columns,
//            with: cellsCopy.rows[fromRow][rectangle.columns]
//          )
//          layout!.rowLayouts[toRow] = .init(rowCells: layout!.cells.rows[toRow])
//        }
//      }
//
//      return .dirtyRectangles([toRectangle])
//
//    case .clear:
//      layout!.cells = .init(size: layout!.cells.size, repeatingElement: .default)
//      layout!.rowLayouts = layout!.cells.rows
//        .map(RowLayout.init(rowCells:))
//      return .needsDisplay
//
//    case let .cursor(_, position):
//      let columnsCount =
//        if
//          position.row < layout!.rowLayouts.count,
//          let rowPart = layout!.rowLayouts[position.row].parts
//            .first(where: { $0.columnsRange.contains(position.column) }),
//            position.column < rowPart.columnsCount,
//            let rowPartCell = rowPart.cells
//              .first(where: {
//                (
//                  (
//                    $0.columnsRange.lowerBound + rowPart.columnsRange
//                      .lowerBound
//                  ) ..<
//                    ($0.columnsRange.upperBound + rowPart.columnsRange.lowerBound)
//                ).contains(position.column)
//              })
//        {
//          rowPartCell.columnsRange.count
//        } else {
//          1
//        }
//
//      return .dirtyRectangles([.init(
//        origin: position,
//        size: .init(columnsCount: columnsCount, rowsCount: 1)
//      )])
//
//    case .clearCursor:
//      return .dirtyRectangles([])
//    }
//  }
//    }
//  }
// }
