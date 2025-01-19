// SPDX-License-Identifier: MIT

import Algorithms
import AppKit
import Collections
import ConcurrencyExtras
import CustomDump
@preconcurrency import QuartzCore

public class GridLayer: CALayer, Rendering {
  private enum DirtyRectangles {
    case all
    case array([IntegerRectangle])

    mutating func formUnion(_ other: DirtyRectangles) {
      switch (self, other) {
      case (_, .all),
           (.all, _):
        self = .all
      case let (.array(array1), .array(array2)):
        self = .array(array1 + array2)
      }
    }

    mutating func append(_ rectangle: IntegerRectangle) {
      switch self {
      case .all:
        self = .all
      case let .array(array):
        self = .array(array + [rectangle])
      }
    }
  }

  private class SurfaceLayer: CALayer {
    override func action(forKey event: String) -> (any CAAction)? {
      NSNull()
    }

    override func hitTest(_: CGPoint) -> CALayer? {
      nil
    }
  }

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

  private let gridID: Grid.ID
  private let store: Store
  private let surfaceLayer = SurfaceLayer()
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
  private var ioSurface: IOSurface?
  private var ioSurfaceGridSize: IntegerSize?
  private var cgContext: CGContext?

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
    gridID = gridLayer.gridID
    store = gridLayer.store
    super.init(layer: layer)
  }

  @MainActor
  init(
    store: Store,
    gridID: Grid.ID,
    contentsScale: Double
  ) {
    self.store = store
    self.gridID = gridID
    super.init()

    self.contentsScale = contentsScale
//    drawsAsynchronously = true
    isOpaque = true
    masksToBounds = true

    surfaceLayer.contentsScale = contentsScale
    surfaceLayer.frame = bounds
//    surfaceLayer.drawsAsynchronously = true
    surfaceLayer.isOpaque = false
    surfaceLayer.contentsGravity = .bottomLeft
    addSublayer(surfaceLayer)

//    ioSurfaceGridSize = grid.size
//    ioSurface = Self
//      .makeIOSurface(
//        contentsScale: contentsScale,
//        cellSize: state.font.cellSize,
//        gridSize: grid.size
//      )
//    surfaceLayer.contents = ioSurface!
//    surfaceLayer.contentsRect = .init(origin: .zero, size: grid.size * state.font.cellSize)
//    cgContext = Self.makeCGContext(ioSurface: ioSurface!)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func action(forKey event: String) -> (any CAAction)? {
    NSNull()
  }

  private static func makeIOSurface(contentsScale: Double, cellSize: CGSize, gridSize: IntegerSize) -> IOSurface {
    let size = gridSize * cellSize * contentsScale
    return .init(
      properties: [
        .width: size.width,
        .height: size.height,
        .bytesPerElement: 4,
        .pixelFormat: kCVPixelFormatType_32BGRA,
      ]
    )!
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

//
//  override public func draw(in ctx: CGContext) {
//    let boundingRect = IntegerRectangle(
//      frame: ctx.boundingBoxOfClipPath.applying(upsideDownTransform),
//      cellSize: state.font.cellSize
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
      shouldRecreateIOSurface = true
    } else if updates.isFontUpdated {
      shouldRecreateIOSurface = true
    } else if updates.updatedLayoutGridIDs.contains(gridID), grid.size != ioSurfaceGridSize {
      shouldRecreateIOSurface = true
    }

    if shouldRecreateIOSurface {
      let ioSurface = Self.makeIOSurface(
        contentsScale: contentsScale,
        cellSize: state.font.cellSize,
        gridSize: grid.size
      )
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
      surfaceLayer.contents = ioSurface
      surfaceLayer.contentsRect = .init(
        origin: .init(),
        size: grid.size * state.font.cellSize
      )
      self.cgContext = cgContext
    }

    var dirtyRectangles = DirtyRectangles.array([])

    if updates.isFontUpdated || updates.isAppearanceUpdated {
      dirtyRectangles.formUnion(.all)
    }

    if
      updates.isCursorBlinkingPhaseUpdated || updates
        .isMouseUserInteractionEnabledUpdated,
        let cursorDrawRun = grid.drawRuns.cursorDrawRun
    {
      dirtyRectangles.append(cursorDrawRun.rectangle)
    }

    if let gridUpdate = updates.gridUpdates[gridID] {
      switch gridUpdate {
      case let .dirtyRectangles(value):
        for rectangle in value {
          dirtyRectangles.append(rectangle)
        }

      case .needsDisplay:
        dirtyRectangles.formUnion(.all)
      }
    }

//    for dirtyRectangle in dirtyRectangles {
//      setNeedsDisplay(
//        (dirtyRectangle * state.font.cellSize)
//          .insetBy(
//            dx: -state.font.cellSize.width * 2,
//            dy: -state.font.cellSize.height
//          )
//          .applying(upsideDownTransform)
//      )
//    }

    let dirtyRectanglesArray: [IntegerRectangle] =
      switch dirtyRectangles {
      case .all:
        [IntegerRectangle(
          origin: .init(),
          size: grid.size
        )]

      case let .array(array):
        array
      }

    if dirtyRectanglesArray.isEmpty {
      return
    }

    ioSurface!.lock(seed: nil)

    cgContext!.setShouldAntialias(false)
    for dirtyRectangle in dirtyRectanglesArray {
      grid.drawRuns
        .drawBackground(
          to: cgContext!,
          boundingRect: dirtyRectangle,
          font: state.font,
          appearance: state.appearance,
          upsideDownTransform: upsideDownTransform,
          contentsScale: contentsScale
        )
    }

    cgContext!.setShouldAntialias(true)
    for dirtyRectangle in dirtyRectanglesArray {
      grid.drawRuns
        .drawForeground(
          to: cgContext!,
          boundingRect: dirtyRectangle,
          font: state.font,
          appearance: state.appearance,
          upsideDownTransform: upsideDownTransform,
          contentsScale: contentsScale
        )
    }

    cgContext!.flush()

    ioSurface!.unlock(seed: nil)

    setNeedsDisplay()

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

    if
      event.phase == .began
    {
      isScrollingHorizontal = nil
      xScrollingAccumulator = 0
      xScrollingReported = -xThreshold / 2
      yScrollingAccumulator = 0
      yScrollingReported = -yThreshold / 2
    }

    let momentumPhaseScrollingSpeedMultiplier = event.momentumPhase
      .rawValue == 0 ? 1 : 0.9
    xScrollingAccumulator -= event
      .scrollingDeltaX * momentumPhaseScrollingSpeedMultiplier
    yScrollingAccumulator -= event
      .scrollingDeltaY * momentumPhaseScrollingSpeedMultiplier

    let xScrollingDelta = xScrollingAccumulator - xScrollingReported
    let yScrollingDelta = yScrollingAccumulator - yScrollingReported

    var horizontalScrollCount = 0
    var verticalScrollCount = 0

    if
      abs(xScrollingDelta) > xThreshold
    {
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
      let modifier = event.modifierFlags.makeModifiers(isSpecialKey: false).joined()
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
    if mouseMove.modifier == previousMouseMove?.modifier, mouseMove.point == previousMouseMove?.point {
      return
    }
    do {
      try store.api.fastCall(APIFunctions.NvimInputMouse(
        button: "move",
        action: "",
        modifier: mouseMove.modifier,
        grid: gridID,
        row: mouseMove.point.row,
        col: mouseMove.point.column
      ))
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
    let modifier = event.modifierFlags.makeModifiers(isSpecialKey: false).joined()
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

extension CycledTimesCollection: @unchecked @retroactive Sendable where Base: Sendable { }
