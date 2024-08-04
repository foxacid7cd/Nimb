// SPDX-License-Identifier: MIT

import AppKit
import CustomDump

public class GridLayer: CALayer, AnchorLayoutingLayer {
  override public init(layer: Any) {
    let gridLayer = layer as! GridLayer
    store = gridLayer.store
    gridID = gridLayer.gridID
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

  public var anchoringLayer: AnchorLayoutingLayer?
  public var anchoredLayers = [ObjectIdentifier: AnchorLayoutingLayer]()
  public var positionInAnchoringLayer = CGPoint()

  public var needsAnchorLayout = false {
    didSet {
      anchoringLayer?.needsAnchorLayout = true
    }
  }

  override public var frame: CGRect {
    didSet {
      setNeedsDisplay()
    }
  }

  @MainActor
  public var grid: Grid {
    if let grid = store.state.grids[gridID] {
      return grid
    } else {
      let gridID = gridID
      log
        .fault(
          "grid view trying to access not created or destroyed grid with id \(gridID)"
        )
      fatalError()
    }
  }

  override public func action(forKey event: String) -> (any CAAction)? {
    NSNull()
  }

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
  public func layoutAnchoredLayers(anchoringLayerOrigin: CGPoint) {
    let origin = anchoringLayerOrigin + positionInAnchoringLayer

    frame = .init(origin: origin, size: grid.size * store.font.cellSize)
      .applying(outerGridUpsideDownTransform)

    anchoredLayers
      .forEach { $0.value.layoutAnchoredLayers(anchoringLayerOrigin: origin) }

    zPosition = grid.zIndex

    needsAnchorLayout = false
  }

  @MainActor
  public func render(
    stateUpdates: State.Updates,
    gridUpdate: Grid.UpdateResult?
  ) {
    dirtyRectangles.removeAll(keepingCapacity: true)

    if stateUpdates.isFontUpdated || stateUpdates.isAppearanceUpdated {
      setNeedsDisplay()
      return
    }

    if
      stateUpdates.isCursorBlinkingPhaseUpdated || stateUpdates
        .isMouseUserInteractionEnabledUpdated,
      let cursorDrawRun = grid.drawRuns.cursorDrawRun
    {
      dirtyRectangles.append(cursorDrawRun.rectangle)
    }

    if let gridUpdate {
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
        (dirtyRectangle * store.font.cellSize)
          .insetBy(
            dx: -store.font.cellSize.width * 2,
            dy: -store.font.cellSize.height
          )
          .applying(upsideDownTransform)
      )
    }
  }

  @MainActor
  override public func draw(in ctx: CGContext) {
    let boundingRect = IntegerRectangle(
      frame: ctx.boundingBoxOfClipPath.applying(upsideDownTransform),
      cellSize: store.font.cellSize
    )

    ctx.setShouldAntialias(false)
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    grid.drawRuns.drawBackground(
      to: ctx,
      boundingRect: boundingRect,
      font: store.font,
      appearance: store.appearance,
      upsideDownTransform: upsideDownTransform
    )
    ctx.endTransparencyLayer()

    ctx.setShouldAntialias(true)
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    grid.drawRuns.drawForeground(
      to: ctx,
      boundingRect: boundingRect,
      font: store.font,
      appearance: store.appearance,
      upsideDownTransform: upsideDownTransform
    )
    ctx.endTransparencyLayer()

    if
      store.state.cursorBlinkingPhase,
      store.state.isMouseUserInteractionEnabled,
      let cursorDrawRun = grid.drawRuns.cursorDrawRun,
      boundingRect.contains(cursorDrawRun.origin)
    {
      cursorDrawRun.draw(
        to: ctx,
        font: store.font,
        appearance: store.appearance,
        upsideDownTransform: upsideDownTransform
      )
    }
  }

  @MainActor
  public func scrollWheel(with event: NSEvent) {
    guard
      store.state.isMouseUserInteractionEnabled,
      store.state.cmdlines.dictionary.isEmpty
    else {
      return
    }

    let scrollingSpeedMultiplier = 1.0
    let xThreshold = store.font.cellWidth * 4 * scrollingSpeedMultiplier
    let yThreshold = store.font.cellHeight * scrollingSpeedMultiplier

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

    if horizontalScrollCount != 0 {
      let point = point(for: event)
      store.reportScrollWheel(
        with: horizontalScrollCount < 0 ? .left : .right,
        modifier: event.modifierFlags
          .makeModifiers(isSpecialKey: false)
          .joined(),
        gridID: gridID,
        point: point
      )
      store.scheduleHideMsgShowsIfPossible()
    }
    if verticalScrollCount != 0 {
      let point = point(for: event)
      store.reportScrollWheel(
        with: verticalScrollCount < 0 ? .up : .down,
        modifier: event.modifierFlags
          .makeModifiers(isSpecialKey: false)
          .joined(),
        gridID: gridID,
        point: point
      )
      store.scheduleHideMsgShowsIfPossible()
    }

    if event.phase == .ended || event.phase == .cancelled {
      hasScrollingSlippedHorizontally = false
      hasScrollingSlippedVertically = false
    }
  }

  @MainActor
  public func reportMouseMove(for event: NSEvent) {
    guard
      store.state.isMouseUserInteractionEnabled,
      store.state.cmdlines.dictionary.isEmpty
    else {
      return
    }
    store.reportMouseMove(
      modifier: event.modifierFlags
        .makeModifiers(isSpecialKey: false)
        .joined(),
      gridID: gridID,
      point: point(for: event)
    )
  }

  @MainActor
  public func point(for event: NSEvent) -> IntegerPoint {
    let upsideDownLocation = convert(event.locationInWindow, from: nil)
      .applying(upsideDownTransform)
    return .init(
      column: Int(upsideDownLocation.x / store.font.cellWidth),
      row: Int(upsideDownLocation.y / store.font.cellHeight)
    )
  }

  @MainActor
  public func windowFrame(forGridFrame gridFrame: IntegerRectangle) -> CGRect {
    let viewFrame = (gridFrame * store.font.cellSize)
      .applying(upsideDownTransform)
    return convert(viewFrame, to: nil)
  }

  @MainActor
  public func report(
    mouseButton: Instance.MouseButton,
    action: Instance.MouseAction,
    with event: NSEvent
  ) {
    guard store.state.isMouseUserInteractionEnabled else {
      return
    }
    let point = point(for: event)
    store.report(
      mouseButton: mouseButton,
      action: action,
      modifier: event.modifierFlags
        .makeModifiers(isSpecialKey: false)
        .joined(),
      gridID: gridID,
      point: point
    )
    store.scheduleHideMsgShowsIfPossible()
  }

  private let gridID: Grid.ID
  private let store: Store
  private var hasScrollingSlippedHorizontally = false
  private var hasScrollingSlippedVertically = false
  private var isScrollingHorizontal: Bool?
  private var xScrollingAccumulator: Double = 0
  private var xScrollingReported: Double = 0
  private var yScrollingAccumulator: Double = 0
  private var yScrollingReported: Double = 0
  private var dirtyRectangles = [IntegerRectangle]()

  @MainActor
  private var upsideDownTransform: CGAffineTransform {
    .init(scaleX: 1, y: -1)
      .translatedBy(x: 0, y: -Double(grid.rowsCount) * store.font.cellHeight)
  }

  @MainActor
  private var outerGridUpsideDownTransform: CGAffineTransform {
    .init(scaleX: 1, y: -1)
      .translatedBy(
        x: 0,
        y: -Double(store.state.outerGrid!.rowsCount) * store.font.cellHeight
      )
  }
}
