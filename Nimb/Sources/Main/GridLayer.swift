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

public class GridLayer: CALayer, Rendering, @unchecked Sendable {
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

  private let store: Store
  private let remoteRenderer: RendererProtocol
  private let gridID: Grid.ID
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
  private let rendererQueue = AsyncQueue()

  @MainActor
  public var grid: Grid {
    if let grid = state.grids[gridID] {
      return grid
    } else {
      let gridID = gridID
      logger
        .fault(
          "grid view trying to access not created or destroyed grid with id \(gridID)"
        )
      fatalError()
    }
  }

  @MainActor
  private var upsideDownTransform: CGAffineTransform {
    .init(scaleX: 1, y: -1)
      .translatedBy(x: 0, y: -Double(grid.rowsCount) * state.font.cellHeight)
  }

  override public init(layer: Any) {
    let gridLayer = layer as! GridLayer

    store = gridLayer.store
    remoteRenderer = gridLayer.remoteRenderer
    gridID = gridLayer.gridID

    super.init(layer: layer)
  }

  @MainActor
  init(
    store: Store,
    remoteRenderer: RendererProtocol,
    gridID: Grid.ID
  ) {
    self.store = store
    self.remoteRenderer = remoteRenderer
    self.gridID = gridID
    super.init()

    drawsAsynchronously = true
    isOpaque = false
    masksToBounds = true

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

  @MainActor
  public func createNewIOSurface() {
    let size = grid.size * state.font.cellSize * contentsScale

    let ioSurface = IOSurface(
      properties: [
        .width: size.width,
        .height: size.height,
        .bytesPerElement: 4,
        .pixelFormat: kCVPixelFormatType_32BGRA,
      ]
    )!
    self.ioSurface = ioSurface
    surfaceLayer.contents = ioSurface
    surfaceLayer.frame = .init(
      origin: .zero,
      size: grid.size * state.font.cellSize
    )
  }

  @MainActor
  public func registerNewGridContext() {
    let gridID = gridID
    let remoteRenderer = remoteRenderer
    let font = state.font
    let contentsScale = contentsScale
    let gridSize = grid.size
    let ioSurface = ioSurface!

    rendererQueue.addOperation {
      await withUnsafeContinuation { continuation in
        remoteRenderer
          .register(
            gridContext: .init(
              font: font.appKit(),
              contentsScale: contentsScale,
              size: gridSize,
              ioSurface: ioSurface
            ),
            forGridWithID: gridID
          ) {
            continuation.resume()
          }
      }
    }
  }

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
    var shouldRecreateIOSurface = false

    if ioSurface == nil {
      createNewIOSurface()
      registerNewGridContext()
    } else {
      if updates.isFontUpdated {
        shouldRecreateIOSurface = true
      }

      if
        updates.updatedLayoutGridIDs.contains(gridID),
        grid.size.columnsCount > previousGridSize.columnsCount || grid.size.rowsCount > previousGridSize.rowsCount
      {
        shouldRecreateIOSurface = true
      }

      if shouldRecreateIOSurface {
        createNewIOSurface()
        registerNewGridContext()
      }
    }

    let dirtyRows = { () -> any Sequence<Int> in
      if
        updates.isFontUpdated || updates.isAppearanceUpdated || shouldRecreateIOSurface
      {
        return 0 ..< grid.rowsCount
      }

      var accumulator = Set<Int>()

      if updates.isCursorBlinkingPhaseUpdated || updates.isMouseUserInteractionEnabledUpdated {
        if let previousCursorRow {
          accumulator.insert(previousCursorRow)
        }
        if let cursor = state.cursor, cursor.gridID == gridID {
          accumulator.insert(cursor.position.row)
        }
      }

//      if
//        updates.isCursorBlinkingPhaseUpdated
//        || updates
//        .isMouseUserInteractionEnabledUpdated,
//        let cursorDrawRun = grid.drawRuns.cursorDrawRun
//      {
//        accumulator.insert(cursorDrawRun.rectangle.origin.row)
//      }

      if let gridUpdate = updates.gridUpdates[gridID] {
        switch gridUpdate {
        case let .dirtyRectangles(rectangles):
          for rectangle in rectangles {
            for row in rectangle.minRow ..< rectangle.maxRow {
              accumulator.insert(row)
            }
          }

        case .needsDisplay:
          return 0 ..< grid.rowsCount
        }
      }

      return accumulator
    }()

    var drawRequestParts = [GridDrawRequestPart]()
    for dirtyRow in dirtyRows {
      let flippedDirtyRow = grid.rowsCount - dirtyRow - 1
      for part in grid.layout.rowLayouts[dirtyRow].parts {
        let decorations = state.appearance.decorations(for: part.highlightID)

        drawRequestParts
          .append(
            .init(
              row: flippedDirtyRow,
              columnsRange: part.columnsRange,
              text: part.text,
              backgroundColor: state.appearance
                .backgroundColor(for: part.highlightID),
              foregroundColor: state.appearance.foregroundColor(
                for: part.highlightID
              ),
              isBold: state.appearance.isBold(for: part.highlightID),
              isItalic: state.appearance.isItalic(for: part.highlightID),
              isStrikethrough: decorations.isStrikethrough,
              isUnderline: decorations.isUnderline,
              isUndercurl: decorations.isUndercurl,
              isUnderdouble: decorations.isUnderdouble,
              isUnderdotted: decorations.isUnderdotted,
              isUnderdashed: decorations.isUnderdashed
            )
          )

        if
          let cursor = state.cursor, cursor.gridID == gridID, cursor.position.row == dirtyRow, part.columnsRange
            .contains(cursor.position.column), state.cursorBlinkingPhase
        {
          var cell: RowPart.Cell?
          let currentColumn = part.columnsRange.startIndex
          for currentCell in part.cells {
            if
              (currentColumn + currentCell.columnsRange.lowerBound ..< currentColumn + currentCell.columnsRange.upperBound).contains(
                cursor.position.column
              )
            {
              cell = currentCell
              break
            }
          }
          drawRequestParts
            .append(
              .init(
                row: flippedDirtyRow,
                columnsRange: currentColumn + cell!.columnsRange.lowerBound ..< currentColumn + cell!.columnsRange.upperBound,
                text: String(part.text[cell!.textRange]),
                backgroundColor: state.appearance.foregroundColor(
                  for: part.highlightID
                ),
                foregroundColor: state.appearance
                  .backgroundColor(for: part.highlightID),
                isBold: state.appearance.isBold(for: part.highlightID),
                isItalic: state.appearance.isItalic(for: part.highlightID),
                isStrikethrough: decorations.isStrikethrough,
                isUnderline: decorations.isUnderline,
                isUndercurl: decorations.isUndercurl,
                isUnderdouble: decorations.isUnderdouble,
                isUnderdotted: decorations.isUnderdotted,
                isUnderdashed: decorations.isUnderdashed
              )
            )
        }
      }
    }

    if !drawRequestParts.isEmpty {
      let remoteRenderer = remoteRenderer
      let gridID = gridID

      rendererQueue.addOperation {
        await withUnsafeContinuation { continuation in
          remoteRenderer
            .draw(
              gridDrawRequest: .init(parts: drawRequestParts),
              forGridWithID: gridID,
              {
                continuation.resume()
              }
            )
        }
        Task { @MainActor in
          self.setNeedsDisplay()
        }
      }
    }

    previousGridSize = grid.size
    previousCursorRow = state.cursor?.gridID == gridID ? state.cursor?.position.row : nil
  }

  @MainActor
  public func scrollWheel(with event: NSEvent) {
    guard
      state.isMouseUserInteractionEnabled,
      state.cmdlines.dictionary.isEmpty
    else {
      return
    }

    let scrollingSpeedMultiplier = 1.1
    let xThreshold = state.font.cellWidth * 8 * scrollingSpeedMultiplier
    let yThreshold = state.font.cellHeight * scrollingSpeedMultiplier

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
    guard
      state.isMouseUserInteractionEnabled,
      state.cmdlines.dictionary.isEmpty
    else {
      return
    }
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
    let upsideDownLocation = convert(event.locationInWindow, from: nil)
      .applying(upsideDownTransform)
    return .init(
      column: Int(upsideDownLocation.x / state.font.cellWidth),
      row: Int(upsideDownLocation.y / state.font.cellHeight)
    )
  }

  @MainActor
  public func windowFrame(forGridFrame gridFrame: IntegerRectangle) -> CGRect {
    let viewFrame = (gridFrame * state.font.cellSize)
      .applying(upsideDownTransform)
    return convert(viewFrame, to: nil)
  }

  @MainActor
  public func report(
    mouseButton: String,
    action: String,
    with event: NSEvent
  ) {
    guard state.isMouseUserInteractionEnabled else {
      return
    }
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
}

extension CycledTimesCollection: @unchecked @retroactive Sendable
where Base: Sendable { }
