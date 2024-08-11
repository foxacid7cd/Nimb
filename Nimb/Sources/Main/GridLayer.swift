// SPDX-License-Identifier: MIT

import AppKit
import ConcurrencyExtras
import CustomDump

public class GridLayer: CALayer, AnchorLayoutingLayer, Rendering {
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

  public var anchoringLayer: AnchorLayoutingLayer?
  public var anchoredLayers = [ObjectIdentifier: AnchorLayoutingLayer]()
  public var positionInAnchoringLayer = CGPoint()

  private let gridID: Grid.ID
  private let store: Store
  @MainActor
  private var hasScrollingSlippedHorizontally = false
  @MainActor
  private var hasScrollingSlippedVertically = false
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

  public var needsAnchorLayout = false {
    didSet {
      if needsAnchorLayout {
        anchoringLayer?.needsAnchorLayout = true
      }
    }
  }

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

  @MainActor
  private var outerGridUpsideDownTransform: CGAffineTransform {
    .init(scaleX: 1, y: -1)
      .translatedBy(
        x: 0,
        y: -Double(state.outerGrid!.rowsCount) * state.font.cellHeight
      )
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
  public func removeAnchoring() {
    for (_, anchoredLayer) in anchoredLayers {
      anchoredLayer.anchoringLayer = nil
    }
    anchoredLayers.removeAll(keepingCapacity: true)

    if let anchoringLayer {
      anchoringLayer.anchoredLayers.removeValue(forKey: .init(self))
    }

    positionInAnchoringLayer = .init()
  }

  @MainActor
  public func layoutAnchoredLayers(
    anchoringLayerOrigin: CGPoint,
    zIndexCounter: Double
  ) {
    let origin = anchoringLayerOrigin + positionInAnchoringLayer

    frame = .init(origin: origin, size: grid.size * state.font.cellSize)
      .applying(outerGridUpsideDownTransform)

    let zIndexModifier =
      switch grid.associatedWindow {
      case let .floating(floating):
        floating.zIndex
      default:
        0
      }
    zPosition = zIndexCounter + Double(zIndexModifier) / 1000

    let nextZIndexCounter = zIndexCounter + 100_000
    for anchoredLayer in anchoredLayers {
      anchoredLayer.value
        .layoutAnchoredLayers(
          anchoringLayerOrigin: origin,
          zIndexCounter: nextZIndexCounter
        )
    }

    needsAnchorLayout = false
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

    let scrollingSpeedMultiplier = 1.0
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
      .rawValue == 0 ? 1 : 0.6
    xScrollingAccumulator -= event
      .scrollingDeltaX * momentumPhaseScrollingSpeedMultiplier
    yScrollingAccumulator -= event
      .scrollingDeltaY * momentumPhaseScrollingSpeedMultiplier

    var xScrollingDelta = xScrollingAccumulator - xScrollingReported
    var yScrollingDelta = yScrollingAccumulator - yScrollingReported

    var horizontalScrollCount = 0
    var verticalScrollCount = 0

    if
      hasScrollingSlippedHorizontally || abs(xScrollingDelta) > xThreshold *
      4
    {
      if !hasScrollingSlippedHorizontally {
        xScrollingDelta = xScrollingAccumulator - xScrollingReported
      }
      hasScrollingSlippedHorizontally = true

      horizontalScrollCount = Int(xScrollingDelta / xThreshold)
      let xScrollingToBeReported = xThreshold * Double(horizontalScrollCount)

      xScrollingReported += xScrollingToBeReported
    }
    if hasScrollingSlippedVertically || abs(yScrollingDelta) > yThreshold * 2 {
      if !hasScrollingSlippedVertically {
        yScrollingDelta = yScrollingAccumulator - yScrollingReported
      }
      hasScrollingSlippedVertically = true

      verticalScrollCount = Int(yScrollingDelta / yThreshold)
      let yScrollingToBeReported = yThreshold * Double(verticalScrollCount)

      yScrollingReported += yScrollingToBeReported
    }

    let point = point(for: event)
    let modifier = event.modifierFlags.makeModifiers(isSpecialKey: false).joined()
    if horizontalScrollCount != 0 {
      store.apiTask { [horizontalScrollCount, gridID] in
        try await $0.nvimInputMouse(
          button: "wheel",
          action: horizontalScrollCount > 0 ? "right" : "left",
          modifier: modifier,
          grid: gridID,
          row: point.row,
          col: point.column
        )
      }
    }
    if verticalScrollCount != 0 {
      store.apiTask { [verticalScrollCount, gridID] in
        try await $0.nvimInputMouse(
          button: "wheel",
          action: verticalScrollCount < 0 ? "up" : "down",
          modifier: modifier,
          grid: gridID,
          row: point.row,
          col: point.column
        )
      }
    }

    if event.phase == .ended || event.phase == .cancelled {
      hasScrollingSlippedHorizontally = false
      hasScrollingSlippedVertically = false
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
      try await $0
        .nvimInputMouse(
          button: "move",
          action: "",
          modifier: mouseMove.modifier,
          grid: gridID,
          row: mouseMove.point.row,
          col: mouseMove.point.column
        )
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
