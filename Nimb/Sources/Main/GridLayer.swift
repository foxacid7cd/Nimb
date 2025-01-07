// SPDX-License-Identifier: MIT

import Algorithms
import AppKit
import Collections
import ConcurrencyExtras
import CoreMedia
import CustomDump
@preconcurrency import IOSurface
import Queue

public class GridLayer: CALayer, Rendering, CALayerDelegate, @unchecked Sendable {
  override public var frame: CGRect {
    didSet {
      surfaceLayer.frame = bounds
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
  private let surfaceLayer = CALayer()
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
  private let remoteRendererAsyncQueue = AsyncQueue()

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

    contentsScale = gridLayer.contentsScale
    drawsAsynchronously = true
    isOpaque = false

    surfaceLayer.frame = bounds
    surfaceLayer.contentsGravity = .bottomLeft
    surfaceLayer.drawsAsynchronously = true
    surfaceLayer.isOpaque = false
    addSublayer(surfaceLayer)

    if let ioSurface = gridLayer.ioSurface {
      surfaceLayer.contents = ioSurface
    }
  }

  init(
    store: Store,
    remoteRenderer: RendererProtocol,
    gridID: Grid.ID
  ) {
    self.store = store
    self.remoteRenderer = remoteRenderer
    self.gridID = gridID
    super.init()

    delegate = self

    drawsAsynchronously = true
    isOpaque = false

    surfaceLayer.delegate = self
    surfaceLayer.frame = bounds
    surfaceLayer.contentsGravity = .bottomLeft
    surfaceLayer.drawsAsynchronously = true
    surfaceLayer.isOpaque = false
    addSublayer(surfaceLayer)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private static func makeIOSurface(contentsScale: CGFloat, gridSize: IntegerSize, cellSize: CGSize) -> IOSurface {
    .init(
      properties: [
        .width: Double(gridSize.columnsCount) * cellSize.width * contentsScale,
        .height: Double(gridSize.rowsCount) * cellSize.height * contentsScale,
        .bytesPerElement: 4,
        .pixelFormat: kCVPixelFormatType_32BGRA,
      ]
    )!
  }

  @MainActor
  public func createNewIOSurface() {
    ioSurface = Self
      .makeIOSurface(
        contentsScale: contentsScale,
        gridSize: grid.size,
        cellSize: state.font.cellSize
      )
    surfaceLayer.contents = ioSurface
  }

  @MainActor
  public func registerNewGridContext() {
    remoteRendererAsyncQueue.addOperation {
      await withCheckedContinuation { continuation in
        self.remoteRenderer
          .register(
            gridContext: .init(
              font: self.state.font.appKit(),
              contentsScale: self.contentsScale,
              size: self.grid.size,
              ioSurface: self.ioSurface!
            ),
            forGridWithID: self.gridID
          ) {
            continuation.resume()
          }
      }
    }
  }

  public nonisolated func action(for layer: CALayer, forKey event: String) -> (any CAAction)? {
    NSNull()
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

//  @MainActor
//  public func createIOSurface() {
//    if bounds.width == 0 || bounds.height == 0 {
//      return
//    }
//
//    let newIOSurface = IOSurface(properties: [
//      .width: bounds.width * contentsScale,
//      .height: bounds.height * contentsScale,
//      .bytesPerElement: 4,
//      .pixelFormat: kCVPixelFormatType_32BGRA,
//    ])!
//    ioSurface = newIOSurface
//    contents = newIOSurface
//
//    surfaceLayer.contents = newIOSurface
//
//    Task {
//      await withCheckedContinuation { continuation in
//        remoteRenderer
//          .register(
//            ioSurface: newIOSurface,
//            scale: contentsScale,
//            forGridWithID: gridID,
//            cb: { isSuccess in
//              if !isSuccess {
//                logger.fault("failed to register IOSurface")
//              }
//              continuation.resume()
//            }
//          )
//      }
//    }
//  }

  @MainActor
  public func render() {
    if ioSurface == nil {
      createNewIOSurface()
      registerNewGridContext()
    } else {
      var shouldRecreateIOSurface = false

      if updates.isFontUpdated {
        shouldRecreateIOSurface = true
      }

      if updates.updatedLayoutGridIDs.contains(gridID) {
        shouldRecreateIOSurface = true
      }

      if shouldRecreateIOSurface {
        createNewIOSurface()
        registerNewGridContext()
      }
    }

    let dirtyRows = { () -> any Sequence<Int> in
      if
        updates.isFontUpdated || updates.isAppearanceUpdated || updates.updatedLayoutGridIDs
          .contains(gridID)
      {
        return 0 ..< grid.rowsCount
      }

      var accumulator = Set<Int>()

      if
        updates.isCursorBlinkingPhaseUpdated
        || updates
        .isMouseUserInteractionEnabledUpdated,
        let cursorDrawRun = grid.drawRuns.cursorDrawRun
      {
        accumulator.insert(cursorDrawRun.rectangle.origin.row)
      }

      if let gridUpdate = updates.gridUpdates[gridID] {
        switch gridUpdate {
        case let .dirtyRectangles(values):
          for value in values {
            accumulator.insert(value.origin.row)
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
      }
    }
    if !drawRequestParts.isEmpty {
      remoteRendererAsyncQueue.addOperation {
        await withCheckedContinuation { continuation in
          self.remoteRenderer
            .draw(
              gridDrawRequest: .init(parts: drawRequestParts),
              forGridWithID: self.gridID,
              {
                continuation.resume()
              }
            )
        }
      }
    }
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

  @MainActor
  public func setNeedsDisplay(rectangle: IntegerRectangle) {
//    setNeedsDisplay()
//    if let ioSurface {
//      surfaceLayer.contents = ioSurface
//    }
//    surfaceLayer.contents = ioSurface
//    surfaceLayer.setNeedsDisplay(
//      rectangle * state.font.cellSize
//        .applying(upsideDownTransform)
//    )
  }
}

extension CycledTimesCollection: @unchecked @retroactive Sendable
where Base: Sendable { }
