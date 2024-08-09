// SPDX-License-Identifier: MIT

import AppKit
import CustomDump

public class GridLayer: CALayer, AnchorLayoutingLayer, Rendering {
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

  override public func action(forKey event: String) -> (any CAAction)? {
    NSNull()
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
  public func layoutAnchoredLayers(anchoringLayerOrigin: CGPoint, index: Int) {
    let origin = anchoringLayerOrigin + positionInAnchoringLayer

    frame = .init(origin: origin, size: grid.size * state.font.cellSize)
      .applying(outerGridUpsideDownTransform)

    anchoredLayers
      .forEach { $0.value.layoutAnchoredLayers(anchoringLayerOrigin: origin, index: index * 10) }

    needsAnchorLayout = false
  }

  @MainActor
  public func render() {
    zPosition = grid.zIndex
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
  override public func draw(in ctx: CGContext) {
    let boundingRect = IntegerRectangle(
      frame: ctx.boundingBoxOfClipPath.applying(upsideDownTransform),
      cellSize: state.font.cellSize
    )

    ctx.setShouldAntialias(false)
    grid.drawRuns.drawBackground(
      to: ctx,
      boundingRect: boundingRect,
      font: state.font,
      appearance: state.appearance,
      upsideDownTransform: upsideDownTransform
    )

    ctx.setShouldAntialias(true)
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

  @MainActor
  public func scrollWheel(with event: NSEvent) {
    guard
      state.isMouseUserInteractionEnabled,
      state.cmdlines.dictionary.isEmpty
    else {
      return
    }

    let scrollingSpeedMultiplier = 1.0
    let xThreshold = state.font.cellWidth * 4 * scrollingSpeedMultiplier
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

//    Task {
//      if horizontalScrollCount != 0, let point = point(for: event) {
//        let scrollWheel = ReportScrollWheel(
//          with: horizontalScrollCount < 0 ? Instance.ScrollDirection.left : Instance.ScrollDirection.right,
//          modifier: event.modifierFlags
//            .makeModifiers(isSpecialKey: false)
//            .joined(),
//          gridID: gridID,
//          point: point
//        ))
//      }
//      if verticalScrollCount != 0 {
//        let point = point(for: event)
//        await store.reportScrollWheel(
//          with: verticalScrollCount < 0 ? .up : .down,
//          modifier: event.modifierFlags
//            .makeModifiers(isSpecialKey: false)
//            .joined(),
//          gridID: gridID,
//          point: point
//        )
//      }
//    }

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
//    store.reportMouseMove(
//      modifier: event.modifierFlags
//        .makeModifiers(isSpecialKey: false)
//        .joined(),
//      gridID: gridID,
//      point: point(for: event)
//    )
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
    mouseButton: Instance.MouseButton,
    action: Instance.MouseAction,
    with event: NSEvent
  ) {
    guard state.isMouseUserInteractionEnabled else {
      return
    }
    let point = point(for: event)
//    store.report(
//      mouseButton: mouseButton,
//      action: action,
//      modifier: event.modifierFlags
//        .makeModifiers(isSpecialKey: false)
//        .joined(),
//      gridID: gridID,
//      point: point
//    )
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
}
