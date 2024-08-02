// SPDX-License-Identifier: MIT

import AppKit
import CustomDump
import Library

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
    actions = [
      "onOrderIn": NSNull(),
      "onOrderOut": NSNull(),
      "sublayers": NSNull(),
      "contents": NSNull(),
      "bounds": NSNull(),
    ]
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
      logger.fault("grid view trying to access not created or destroyed grid with id \(gridID)")
      fatalError()
    }
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

    anchoredLayers.forEach { $0.value.layoutAnchoredLayers(anchoringLayerOrigin: origin) }

    zPosition = grid.zIndex

    needsAnchorLayout = false
  }

  @MainActor
  public func render(stateUpdates: State.Updates, gridUpdate: Grid.UpdateResult?) {
    dirtyRectangles.removeAll(keepingCapacity: true)

    if stateUpdates.isFontUpdated || stateUpdates.isAppearanceUpdated {
      setNeedsDisplay()
      return
    }

    if
      stateUpdates.isCursorBlinkingPhaseUpdated || stateUpdates.isMouseUserInteractionEnabledUpdated,
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
          .insetBy(dx: -store.font.cellSize.width * 2, dy: -store.font.cellSize.height)
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

    ctx.flush()
  }

//  override public func mouseDown(with event: NSEvent) {
//    report(mouseButton: .left, action: .press, with: event)
//  }
//
//  override public func mouseDragged(with event: NSEvent) {
//    report(mouseButton: .left, action: .drag, with: event)
//  }
//
//  override public func mouseUp(with event: NSEvent) {
//    report(mouseButton: .left, action: .release, with: event)
//  }
//
//  override public func rightMouseDown(with event: NSEvent) {
//    report(mouseButton: .right, action: .press, with: event)
//  }
//
//  override public func rightMouseDragged(with event: NSEvent) {
//    report(mouseButton: .right, action: .drag, with: event)
//  }
//
//  override public func rightMouseUp(with event: NSEvent) {
//    report(mouseButton: .right, action: .release, with: event)
//  }
//
//  override public func otherMouseDown(with event: NSEvent) {
//    report(mouseButton: .middle, action: .press, with: event)
//  }
//
//  override public func otherMouseDragged(with event: NSEvent) {
//    report(mouseButton: .middle, action: .drag, with: event)
//  }
//
//  override public func otherMouseUp(with event: NSEvent) {
//    report(mouseButton: .middle, action: .release, with: event)
//  }
//
//  override public func scrollWheel(with event: NSEvent) {
//    guard
//      store.state.isMouseUserInteractionEnabled,
//      store.state.cmdlines.dictionary.isEmpty
//    else {
//      return
//    }
//
//    let scrollingSpeedMultiplier = 0.8
//    let xThreshold = store.font.cellWidth * 6 * scrollingSpeedMultiplier
//    let yThreshold = store.font.cellHeight * 3 * scrollingSpeedMultiplier
//
//    if event.phase == .began {
//      isScrollingHorizontal = nil
//      xScrollingAccumulator = 0
//      xScrollingReported = -xThreshold / 2
//      yScrollingAccumulator = 0
//      yScrollingReported = -yThreshold / 2
//    }
//
//    let momentumPhaseScrollingSpeedMultiplier = event.momentumPhase.rawValue == 0 ? 1 : 0.6
//    xScrollingAccumulator -= event.scrollingDeltaX * momentumPhaseScrollingSpeedMultiplier
//    yScrollingAccumulator -= event.scrollingDeltaY * momentumPhaseScrollingSpeedMultiplier
//
//    var direction: Instance.ScrollDirection?
//    var count = 0
//
//    let xScrollingDelta = xScrollingAccumulator - xScrollingReported
//    let yScrollingDelta = yScrollingAccumulator - yScrollingReported
//    if isScrollingHorizontal != true, abs(yScrollingDelta) > yThreshold {
//      if isScrollingHorizontal == nil {
//        isScrollingHorizontal = false
//      }
//
//      count = Int(abs(yScrollingDelta) / yThreshold)
//      let yScrollingToBeReported = yThreshold * Double(count)
//      if yScrollingDelta > 0 {
//        direction = .down
//        yScrollingReported += yScrollingToBeReported
//      } else {
//        direction = .up
//        yScrollingReported -= yScrollingToBeReported
//      }
//
//    } else if isScrollingHorizontal != false, abs(xScrollingDelta) > xThreshold {
//      if isScrollingHorizontal == nil {
//        isScrollingHorizontal = true
//      }
//
//      count = Int(abs(xScrollingDelta) / xThreshold)
//      let xScrollingToBeReported = xThreshold * Double(count)
//      if xScrollingDelta > 0 {
//        direction = .right
//        xScrollingReported += xScrollingToBeReported
//      } else {
//        direction = .left
//        xScrollingReported -= xScrollingToBeReported
//      }
//    }
//
//    if let direction, count > 0 {
//      let point = point(for: event)
//      Task {
//        await store.reportScrollWheel(
//          with: direction,
//          modifier: event.modifierFlags
//            .makeModifiers(isSpecialKey: false)
//            .joined(),
//          gridID: gridID,
//          point: point,
//          count: count
//        )
//        await store.scheduleHideMsgShowsIfPossible()
//      }
//    }
//  }
//
//  public func reportMouseMove(for event: NSEvent) {
//    guard store.state.isMouseUserInteractionEnabled, store.state.cmdlines.dictionary.isEmpty else {
//      return
//    }
//    Task {
//      await store.reportMouseMove(
//        modifier: event.modifierFlags
//          .makeModifiers(isSpecialKey: false)
//          .joined(),
//        gridID: gridID,
//        point: point(for: event)
//      )
//    }
//  }
//
//  public func point(for event: NSEvent) -> IntegerPoint {
//    let upsideDownLocation = convert(event.locationInWindow, from: nil)
//      .applying(upsideDownTransform)
//    return .init(
//      column: Int(upsideDownLocation.x / store.font.cellWidth),
//      row: Int(upsideDownLocation.y / store.font.cellHeight)
//    )
//  }
//
  @MainActor
  public func windowFrame(forGridFrame gridFrame: IntegerRectangle) -> CGRect {
    let viewFrame = (gridFrame * store.font.cellSize)
      .applying(upsideDownTransform)
    return convert(viewFrame, to: nil)
  }

  private let gridID: Grid.ID
  private let store: Store
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
      .translatedBy(x: 0, y: -Double(store.state.outerGrid!.rowsCount) * store.font.cellHeight)
  }

//  @MainActor
//  private func report(mouseButton: Instance.MouseButton, action: Instance.MouseAction, with event: NSEvent) {
//    guard store.state.isMouseUserInteractionEnabled else {
//      return
//    }
//    let point = point(for: event)
//    Task {
//      await store.report(
//        mouseButton: mouseButton,
//        action: action,
//        modifier: event.modifierFlags
//          .makeModifiers(isSpecialKey: false)
//          .joined(),
//        gridID: gridID,
//        point: point
//      )
//      await store.scheduleHideMsgShowsIfPossible()
//    }
//  }
}
