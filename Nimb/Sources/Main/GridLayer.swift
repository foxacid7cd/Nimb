// SPDX-License-Identifier: MIT

import Algorithms
import AppKit
import Collections
import ConcurrencyExtras
import CustomDump
import Queue

public class GridLayer: CALayer, Rendering, @unchecked Sendable {
  private let gridID: Grid.ID
  private let store: Store
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

  @MainActor
  public var grid: Grid? {
    guard isRendered else {
      return nil
    }
    return state.grids[gridID]
  }

  @MainActor
  private var upsideDownTransform: CGAffineTransform? {
    guard let grid else {
      return nil
    }
    return .init(scaleX: 1, y: -1)
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
    gridID: Grid.ID
  ) {
    self.store = store
    self.gridID = gridID
    super.init()

    masksToBounds = true
    drawsAsynchronously = true
    needsDisplayOnBoundsChange = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func action(forKey event: String) -> (any CAAction)? {
    NSNull()
  }

  override public func draw(in ctx: CGContext) {
    MainActor.assumeIsolated {
      guard isRendered, let grid, let upsideDownTransform else {
        return
      }

      ctx.saveGState()
      defer { ctx.restoreGState() }

      let boundingRect = IntegerRectangle(
        frame: ctx.boundingBoxOfClipPath.applying(upsideDownTransform),
        cellSize: state.font.cellSize
      )

      ctx.setAllowsAntialiasing(false)
      ctx.setAllowsFontSmoothing(false)
      ctx.setShouldAntialias(false)
      ctx.setShouldSmoothFonts(false)
      grid.drawRuns.drawBackground(
        to: ctx,
        boundingRect: boundingRect,
        font: state.font,
        appearance: state.appearance,
        upsideDownTransform: upsideDownTransform
      )

      ctx.setAllowsAntialiasing(true)
      ctx.setAllowsFontSmoothing(true)
      ctx.setShouldAntialias(true)
      ctx.setShouldSmoothFonts(true)
      grid.drawRuns.drawForeground(
        to: ctx,
        boundingRect: boundingRect,
        font: state.font,
        appearance: state.appearance,
        upsideDownTransform: upsideDownTransform
      )

      if
        state.cursorBlinkingPhase,
        state.isMouseUserInteractionEnabled,
        let cursorDrawRun = grid.drawRuns.cursorDrawRun,
        boundingRect.contains(cursorDrawRun.origin)
      {
        cursorDrawRun.draw(
          to: ctx,
          font: state.font,
          appearance: state.appearance,
          upsideDownTransform: upsideDownTransform
        )
      }
    }
  }

  @MainActor
  public func render() {
    if let dirtyRect = calculateDirtyRect() {
      setNeedsDisplay(dirtyRect)
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

    let xThreshold = state.font.cellWidth * 12
    let yThreshold = state.font.cellHeight * 1.25

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

      store.api
        .fastCallsTransaction(
          with: chain(horizontalScrollFunctions, verticalScrollFunctions)
        )
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
    store.api.fastCall(APIFunctions.NvimInputMouse(
      button: "move",
      action: "",
      modifier: mouseMove.modifier,
      grid: gridID,
      row: mouseMove.point.row,
      col: mouseMove.point.column
    ))
    previousMouseMove = mouseMove
  }

  @MainActor
  public func point(for event: NSEvent) -> IntegerPoint {
    guard let upsideDownTransform else {
      return .init()
    }
    let upsideDownLocation = convert(event.locationInWindow, from: nil)
      .applying(upsideDownTransform)
    return .init(
      column: Int(upsideDownLocation.x / state.font.cellWidth),
      row: Int(upsideDownLocation.y / state.font.cellHeight)
    )
  }

  @MainActor
  public func windowFrame(forGridFrame gridFrame: IntegerRectangle) -> CGRect {
    guard let upsideDownTransform else {
      return .init()
    }
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
    store.api.fastCall(APIFunctions.NvimInputMouse(
      button: mouseButton,
      action: action,
      modifier: modifier,
      grid: gridID,
      row: point.row,
      col: point.column
    ))
  }

  @MainActor
  private func calculateDirtyRect() -> CGRect? {
    guard isRendered, let grid, let upsideDownTransform else {
      return .zero
    }
    if updates.isFontUpdated || updates.isAppearanceUpdated {
      return bounds
    }

    var dirtyRect: CGRect?

    if let gridUpdate = updates.gridUpdates[gridID] {
      switch gridUpdate {
      case let .dirtyRectangles(value):
        for rectangle in value {
          let rect = (rectangle * state.font.cellSize)
            .insetBy(dx: -state.font.cellSize.width, dy: 0)
            .applying(upsideDownTransform)
          dirtyRect = dirtyRect.map { $0.union(rect) } ?? rect
        }

      case .needsDisplay:
        return bounds
      }
    }

    if
      let cursorDrawRun = grid.drawRuns.cursorDrawRun,
      updates.isCursorBlinkingPhaseUpdated || updates.isMouseUserInteractionEnabledUpdated
    {
      let rect = (cursorDrawRun.rectangle * state.font.cellSize)
        .applying(upsideDownTransform)
      dirtyRect = dirtyRect.map { $0.union(rect) } ?? rect
    }

    return dirtyRect
  }
}

extension CycledTimesCollection: @unchecked @retroactive Sendable where Base: Sendable { }

extension CGContext: @unchecked @retroactive Sendable { }
