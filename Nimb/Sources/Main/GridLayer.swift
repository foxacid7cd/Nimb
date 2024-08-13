// SPDX-License-Identifier: MIT

import Algorithms
import AppKit
import Collections
import ConcurrencyExtras
import CustomDump

public class GridLayer: CALayer, Rendering {
  private struct Critical {
    var grid: Grid
    var font: Font
    var appearance: Appearance
    var cursorBlinkingPhase: Bool
    var isMouseUserInteractionEnabled: Bool

    var upsideDownTransform: CGAffineTransform {
      .init(scaleX: 1, y: -1)
        .translatedBy(x: 0, y: -Double(grid.rowsCount) * font.cellHeight)
    }
  }

  override public var frame: CGRect {
    didSet {
      setNeedsDisplay()
    }
  }

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
  @MainActor
  private var dirtyRectangles = [IntegerRectangle]()
  private var critical = LockIsolated<Critical?>(nil)
  private var previousMouseMove: (modifier: String, point: IntegerPoint)?

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

  init(store: Store, gridID: Grid.ID) {
    self.store = store
    self.gridID = gridID
    super.init()

    drawsAsynchronously = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func action(forKey event: String) -> (any CAAction)? {
    NSNull()
  }

  override public func draw(in ctx: CGContext) {
    guard let critical = critical.withValue({ $0 }) else {
      return
    }

    let boundingRect = IntegerRectangle(
      frame: ctx.boundingBoxOfClipPath.applying(critical.upsideDownTransform),
      cellSize: critical.font.cellSize
    )

    ctx.setShouldAntialias(false)
    critical.grid.drawRuns.drawBackground(
      to: ctx,
      boundingRect: boundingRect,
      font: critical.font,
      appearance: critical.appearance,
      upsideDownTransform: critical.upsideDownTransform
    )

    ctx.setShouldAntialias(true)
    critical.grid.drawRuns.drawForeground(
      to: ctx,
      boundingRect: boundingRect,
      font: critical.font,
      appearance: critical.appearance,
      upsideDownTransform: critical.upsideDownTransform
    )

    if
      critical.cursorBlinkingPhase,
      critical.isMouseUserInteractionEnabled,
      let cursorDrawRun = critical.grid.drawRuns.cursorDrawRun,
      boundingRect.contains(cursorDrawRun.origin)
    {
      cursorDrawRun.draw(
        to: ctx,
        font: critical.font,
        appearance: critical.appearance,
        upsideDownTransform: critical.upsideDownTransform
      )
    }
  }

  @MainActor
  public func render() {
    let critical = Critical(
      grid: grid,
      font: state.font,
      appearance: state.appearance,
      cursorBlinkingPhase: state.cursorBlinkingPhase,
      isMouseUserInteractionEnabled: state.isMouseUserInteractionEnabled
    )
    self.critical.withValue { $0 = critical }

    dirtyRectangles.removeAll(keepingCapacity: true)

    if updates.isFontUpdated || updates.isAppearanceUpdated {
      setNeedsDisplay()
      return
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
        dirtyRectangles.append(contentsOf: value)

      case .needsDisplay:
        setNeedsDisplay()
        return
      }
    }

    for dirtyRectangle in dirtyRectangles {
      setNeedsDisplay(
        (dirtyRectangle * state.font.cellSize)
          .insetBy(
            dx: -state.font.cellSize.width * 2,
            dy: -state.font.cellSize.height
          )
          .applying(upsideDownTransform)
      )
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

    let scrollingSpeedMultiplier = 1.15
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
      .rawValue == 0 ? 1 : 0.85
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

      store.apiTask { [horizontalScrollFunctions, verticalScrollFunctions] in
        try await $0
          .fastCallsTransaction(
            with: chain(horizontalScrollFunctions, verticalScrollFunctions)
          )
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
    store.apiTask { [gridID] in
      try $0.fastCall(APIFunctions.NvimInputMouse(
        button: "move",
        action: "",
        modifier: mouseMove.modifier,
        grid: gridID,
        row: mouseMove.point.row,
        col: mouseMove.point.column
      ))
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
