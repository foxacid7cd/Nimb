// SPDX-License-Identifier: MIT

import Algorithms
import AppKit
import NimbCore
import NimbNeovim
import NimbState

public class GridView: NSView, CALayerDelegate, Rendering {
  /// Which way the current gesture has committed to, if it has. Pinning to one
  /// axis keeps a crooked swipe from drifting sideways as it accumulates.
  private enum ScrollAxis {
    /// Not enough travel yet to tell.
    case undecided
    case vertical
    case horizontal
    /// Deliberately diagonal, so neither axis is suppressed.
    case free
  }

  /// Most lines or columns one wheel event may ask Neovim to scroll. The
  /// remainder is dropped, so a hard flick cannot commit to a long redraw.
  static let maxScrollStep = 15

  /// How far a gesture must travel before it is pinned to an axis, so the
  /// first event alone does not decide it.
  private static let scrollAxisLockThreshold = 6.0

  /// How much one axis must lead the other to pin the gesture. Only a
  /// genuinely diagonal one stays unpinned.
  private static let scrollAxisLockRatio = 2.0

  /// Lines of content per cell of finger travel. Tuned by feel.
  private static let scrollLinesPerCell = 2.0

  /// Columns of content per cell of finger travel. One to one, as before.
  private static let scrollColumnsPerCell = 1.0

  override public var frame: NSRect {
    didSet {
      gridLayer.frame = bounds
      gridLayer.updateDrawableSize()
      coreGraphicsLayer.frame = bounds
    }
  }

  public var renderContext: RenderContext! = nil

  private let store: Store
  private let gridID: Grid.ID
  private let gridLayer: GridLayer
  private let coreGraphicsLayer: GridCoreGraphicsLayer
  private let scrollbarLayer = CALayer()
  private var scrollbarHideTask: Task<Void, Never>? = nil
  /// nil until the first render, so the first pass always applies visibility.
  private var renderingMode: Bool? = nil
  /// Bounds the last frame was built for. A resize changes every rect in the
  /// scene without producing a grid update. nil means nothing built yet.
  private var builtBounds: CGRect? = nil
  private let metalSceneBuilder: GridMetalSceneBuilder?
  /// What the state says about this grid's visibility, kept apart from
  /// whether the view has anything to show yet.
  private var isHiddenByState = false
  /// Whether the Metal layer has a frame to draw yet. A new grid is composited
  /// before its first drawable exists, which shows as a hole.
  private var hasPresentedFrame = false

  private var scrollAxis: ScrollAxis = .undecided
  private var xScrollingAccumulator: Double = 0
  private var xScrollingReported: Double = 0
  private var yScrollingAccumulator: Double = 0
  private var yScrollingReported: Double = 0
  private var previousMouseMove: (modifier: String, point: IntegerPoint)? = nil

  /// Mirrors what `mousescroll` was last set to, so it is pushed only on
  /// change. Starts at zero, since the config may have set it itself.
  private var scrollLinesPerEvent = 0
  private var scrollColumnsPerEvent = 0

  public var grid: Grid? {
    guard isRendered else {
      return nil
    }
    return state.grids[gridID]
  }

  /// Anchored to the view's own height, not the grid's: a grid clipped to the
  /// screen keeps its first row at the top of what is left of it.
  private var upsideDownTransform: CGAffineTransform? {
    guard grid != nil else {
      return nil
    }
    return .init(scaleX: 1, y: -1)
      .translatedBy(x: 0, y: -bounds.height)
  }

  /// Whether this frame can change what this grid looks like. Both layers keep
  /// what they last drew, so false leaves the correct pixels on screen.
  private var isAffectedByCurrentUpdates: Bool {
    if builtBounds != bounds {
      return true
    }
    // Font and appearance reshape or recolour every run in every grid.
    if updates.isFontUpdated || updates.isAppearanceUpdated {
      return true
    }
    // The cursor is drawn from the snapshot rather than from a grid update, so
    // anything that gates it has to invalidate on its own.
    if updates.isBusyUpdated || updates.isCursorBlinkingPhaseUpdated || updates.isApplicationActiveUpdated {
      return true
    }
    // Both halves of a cursor move arrive here too: .clearCursor to the old
    // grid and .cursor to the new one.
    if updates.gridUpdates[gridID] != nil {
      return true
    }
    // Size or visibility changed; the frame may not have been applied yet, so
    // builtBounds alone would not catch it.
    return updates.updatedLayoutGridIDs.contains(gridID)
  }

  public init(frame frameRect: NSRect, store: Store, gridID: Grid.ID) {
    self.store = store
    self.gridID = gridID
    metalSceneBuilder = GridMetalRenderer.shared.map(GridMetalSceneBuilder.init(renderer:))
    gridLayer = .init(store: store, gridID: gridID)
    coreGraphicsLayer = .init(gridID: gridID)
    super.init(frame: frameRect)

    wantsLayer = true
    canDrawConcurrently = true
    layer!.isOpaque = false
    layer!.drawsAsynchronously = true
    layer!.delegate = self
    layer!.masksToBounds = true

    gridLayer.frame = bounds
    gridLayer.updateDrawableSize()
    gridLayer.delegate = self
    gridLayer.onFirstFrameReady = { [weak self] in
      self?.markPresented()
    }
    layer!.addSublayer(gridLayer)

    // Hidden until the first frame lands. Without this a new grid is on screen
    // for at least one compositor pass with no drawable behind it.
    isHidden = true

    coreGraphicsLayer.frame = bounds
    coreGraphicsLayer.delegate = self
    coreGraphicsLayer.isHidden = true
    layer!.addSublayer(coreGraphicsLayer)

    scrollbarLayer.backgroundColor = NSColor.labelColor
      .withAlphaComponent(0.35)
      .cgColor
    scrollbarLayer.cornerRadius = 2
    scrollbarLayer.isHidden = true
    layer!.addSublayer(scrollbarLayer)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewWillMove(toWindow newWindow: NSWindow?) {
    super.viewWillMove(toWindow: newWindow)

    guard let newWindow else {
      return
    }
    apply(backingScale: newWindow.backingScaleFactor)
  }

  /// Backing scale can change without the view changing window. The Metal path
  /// takes contentsScale as gospel for glyph rasterisation and drawable size.
  override public func viewDidChangeBackingProperties() {
    super.viewDidChangeBackingProperties()

    guard let scale = window?.backingScaleFactor else {
      return
    }
    apply(backingScale: scale)
  }

  override public func updateTrackingAreas() {
    super.updateTrackingAreas()

    for trackingArea in trackingAreas {
      removeTrackingArea(trackingArea)
    }

    addTrackingArea(.init(
      rect: bounds,
      options: [.inVisibleRect, .activeInKeyWindow, .mouseMoved],
      owner: self,
      userInfo: nil,
    ))
  }

  override public func scrollWheel(with event: NSEvent) {
    guard state.isMouseUserInteractionEnabled else {
      return
    }

    // One wheel event per gesture step, distance carried by `mousescroll`: a
    // redraw costs Neovim the same whatever the distance.
    let linePoints = state.font.cellHeight / Self.scrollLinesPerCell
    let columnPoints = state.font.cellWidth / Self.scrollColumnsPerCell

    if event.phase == .began {
      scrollAxis = .undecided
      xScrollingAccumulator = 0
      xScrollingReported = 0
      yScrollingAccumulator = 0
      yScrollingReported = 0
    }

    let momentumPhaseScrollingSpeedMultiplier = event.momentumPhase
      .rawValue == 0 ? 1 : 0.9
    xScrollingAccumulator -= event
      .scrollingDeltaX * momentumPhaseScrollingSpeedMultiplier
    yScrollingAccumulator -= event
      .scrollingDeltaY * momentumPhaseScrollingSpeedMultiplier

    // Only trackpads get pinned. A mouse wheel reports no gesture phases, so
    // there is nothing to scope a lock to, and its axes are discrete anyway.
    if event.hasPreciseScrollingDeltas, scrollAxis == .undecided {
      let travelledX = abs(xScrollingAccumulator)
      let travelledY = abs(yScrollingAccumulator)

      if max(travelledX, travelledY) >= Self.scrollAxisLockThreshold {
        if travelledY >= travelledX * Self.scrollAxisLockRatio {
          scrollAxis = .vertical
        } else if travelledX >= travelledY * Self.scrollAxisLockRatio {
          scrollAxis = .horizontal
        } else {
          scrollAxis = .free
        }
      }
    }

    // Whatever the pinned axis discards is marked as reported, so it cannot
    // accumulate quietly and lurch the moment the next gesture begins.
    switch scrollAxis {
    case .vertical:
      xScrollingReported = xScrollingAccumulator
    case .horizontal:
      yScrollingReported = yScrollingAccumulator
    case .free,
         .undecided:
      break
    }

    let xScrollingDelta = xScrollingAccumulator - xScrollingReported
    let yScrollingDelta = yScrollingAccumulator - yScrollingReported

    // Whole steps only; the remainder stays in the accumulator for the next
    // event rather than being rounded away.
    var columnsToScroll = Int(xScrollingDelta / columnPoints)
    var linesToScroll = Int(yScrollingDelta / linePoints)

    // Capped so one violent flick cannot ask for a scroll that takes Neovim
    // seconds to draw. The remainder is dropped, not queued.
    columnsToScroll = max(-Self.maxScrollStep, min(Self.maxScrollStep, columnsToScroll))
    linesToScroll = max(-Self.maxScrollStep, min(Self.maxScrollStep, linesToScroll))

    guard columnsToScroll != 0 || linesToScroll != 0 else {
      return
    }

    xScrollingReported += Double(columnsToScroll) * columnPoints
    yScrollingReported += Double(linesToScroll) * linePoints

    let modifier = event.modifierFlags.makeModifiers(isSpecialKey: false).joined()
    let point = point(for: event)

    // The option and the events go out in one write, in this order, so Neovim
    // has the distance before the step it applies to.
    var calls = [any APIFunction]()

    let verticalDistance = max(abs(linesToScroll), 1)
    let horizontalDistance = max(abs(columnsToScroll), 1)
    if verticalDistance != scrollLinesPerEvent || horizontalDistance != scrollColumnsPerEvent {
      scrollLinesPerEvent = verticalDistance
      scrollColumnsPerEvent = horizontalDistance
      calls.append(APIFunctions.NvimSetOptionValue(
        name: "mousescroll",
        value: .string("ver:\(verticalDistance),hor:\(horizontalDistance)"),
        opts: [:],
      ))
    }

    if columnsToScroll != 0 {
      calls.append(APIFunctions.NvimInputMouse(
        button: "wheel",
        action: columnsToScroll < 0 ? "left" : "right",
        modifier: modifier,
        grid: gridID,
        row: point.row,
        col: point.column,
      ))
    }
    if linesToScroll != 0 {
      calls.append(APIFunctions.NvimInputMouse(
        button: "wheel",
        action: linesToScroll < 0 ? "up" : "down",
        modifier: modifier,
        grid: gridID,
        row: point.row,
        col: point.column,
      ))
    }

    store.api.fastCallsTransaction(with: calls)
  }

  /// Set by GridsView from the state. The view stays hidden until it has also
  /// drawn once.
  public func setHiddenByState(_ isHidden: Bool) {
    isHiddenByState = isHidden
    updateVisibility()
  }

  public nonisolated func action(for layer: CALayer, forKey event: String) -> (any CAAction)? {
    NSNull()
  }

  public func render() {
    renderStats.count(.gridsVisited)
    let isCoreGraphics = state.debug.isCoreGraphicsRenderingEnabled

    // Kept in step with the editor background, so any moment the drawable does
    // not cover shows the right colour instead of nothing.
    if updates.isAppearanceUpdated || !hasPresentedFrame {
      gridLayer.setBackground(state.appearance.defaultBackgroundColor)
    }
    renderScrollbar()

    // Only the Metal layer has nothing to show until it presents. The
    // CoreGraphics layer would wait for a frame that never comes.
    if isCoreGraphics || metalSceneBuilder == nil {
      markPresented()
    }

    // Compared against the mode in effect, not updates.isDebugUpdated, which is
    // false on the first render: the flag is restored, not toggled.
    let didSwitchRenderingMode = renderingMode != isCoreGraphics
    if didSwitchRenderingMode {
      renderingMode = isCoreGraphics
      // Each layer keeps what it last drew, so hide the outgoing one and make
      // the incoming one repaint from scratch.
      gridLayer.isHidden = isCoreGraphics
      coreGraphicsLayer.isHidden = !isCoreGraphics
      if isCoreGraphics {
        coreGraphicsLayer.setNeedsDisplay()
      } else {
        gridLayer.setNeedsDisplay()
      }
    }

    guard let renderInput = makeRenderInput() else {
      builtBounds = nil
      gridLayer.update(renderInput: nil)
      coreGraphicsLayer.update(renderInput: nil)
      return
    }

    guard didSwitchRenderingMode || isAffectedByCurrentUpdates else {
      return
    }
    renderStats.count(.gridsBuilt)
    builtBounds = bounds

    // The CoreGraphics path stays synchronous: its work happens inside
    // draw(in:), and it is the control the Metal path is measured against.
    guard !isCoreGraphics else {
      coreGraphicsLayer.update(renderInput: renderInput)
      coreGraphicsLayer.render()
      return
    }

    guard let metalSceneBuilder else {
      // No Metal at all. Hand the snapshot over so GridLayer.display falls
      // through to draw(in:).
      gridLayer.update(renderInput: renderInput)
      gridLayer.render()
      return
    }

    GridSceneBuildQueue.shared.submit(
      gridID: gridID,
      target: gridLayer,
      builder: metalSceneBuilder,
      snapshot: renderInput.snapshot,
      updates: renderInput.updates,
      bounds: bounds,
      scale: max(gridLayer.contentsScale, 1),
    )
  }

  public func reportMouseMove(for event: NSEvent) {
    guard state.isMouseUserInteractionEnabled else {
      return
    }
    let mouseMove = (
      modifier: event.modifierFlags.makeModifiers(isSpecialKey: false).joined(),
      point: point(for: event),
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
      col: mouseMove.point.column,
    ))
    previousMouseMove = mouseMove
  }

  public func point(for event: NSEvent) -> IntegerPoint {
    guard let upsideDownTransform else {
      return .init()
    }
    let upsideDownLocation = convert(event.locationInWindow, from: nil)
      .applying(upsideDownTransform)
    return .init(
      // floor, not Int(): a drag past this view's edge produces negative
      // coordinates, and Int() truncates toward zero instead of down.
      column: Int((upsideDownLocation.x / state.font.cellWidth).rounded(.down)),
      row: Int((upsideDownLocation.y / state.font.cellHeight).rounded(.down)),
    )
  }

  public func windowFrame(forGridFrame gridFrame: IntegerRectangle) -> CGRect {
    guard let upsideDownTransform else {
      return .init()
    }
    let viewFrame = (gridFrame * state.font.cellSize)
      .applying(upsideDownTransform)
    return convert(viewFrame, to: nil)
  }

  public func report(
    mouseButton: String,
    action: String,
    with event: NSEvent,
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
      col: point.column,
    ))
  }

  private func renderScrollbar() {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    defer { CATransaction.commit() }

    guard
      gridID != Grid.OuterID,
      let grid = state.grids[gridID],
      case .some(.plain) = grid.associatedWindow,
      let viewport = state.viewports[gridID],
      viewport.lineCount > 0
    else {
      scrollbarHideTask?.cancel()
      scrollbarHideTask = nil
      scrollbarLayer.isHidden = true
      return
    }

    let margins = state.viewportMargins[gridID]
    let topInset = CGFloat(margins?.top ?? 0) * state.font.cellHeight
    let bottomInset = CGFloat(margins?.bottom ?? 0) * state.font.cellHeight
    let trackHeight = bounds.height - topInset - bottomInset
    let visibleLineCount = max(viewport.bottomLine - viewport.topLine, 1)
    let thumbHeight = max(20, trackHeight * CGFloat(visibleLineCount) / CGFloat(viewport.lineCount))

    guard trackHeight > 0, thumbHeight < trackHeight else {
      scrollbarLayer.isHidden = true
      return
    }

    let scrollableLineCount = max(viewport.lineCount - visibleLineCount, 1)
    let progress = min(
      max(CGFloat(viewport.topLine) / CGFloat(scrollableLineCount), 0),
      1,
    )
    let width: CGFloat = 4
    let horizontalInset: CGFloat = 3
    scrollbarLayer.frame = .init(
      x: bounds.maxX - width - horizontalInset,
      y: bounds.maxY - topInset - thumbHeight - progress * (trackHeight - thumbHeight),
      width: width,
      height: thumbHeight,
    )
    if updates.updatedViewportGridIDs.contains(gridID) {
      scrollbarLayer.isHidden = false
      scheduleScrollbarHide()
    }
  }

  private func scheduleScrollbarHide() {
    scrollbarHideTask?.cancel()
    scrollbarHideTask = Task { @MainActor [weak self] in
      try? await Task.sleep(for: .seconds(1.5))
      guard !Task.isCancelled else {
        return
      }
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      self?.scrollbarLayer.isHidden = true
      CATransaction.commit()
    }
  }

  private func updateVisibility() {
    isHidden = isHiddenByState || !hasPresentedFrame
  }

  private func markPresented() {
    guard !hasPresentedFrame else {
      return
    }
    hasPresentedFrame = true
    updateVisibility()
  }

  private func apply(backingScale scale: CGFloat) {
    guard gridLayer.contentsScale != scale else {
      return
    }

    layer!.contentsScale = scale
    gridLayer.contentsScale = scale
    gridLayer.updateDrawableSize()
    coreGraphicsLayer.contentsScale = scale

    // The atlas is keyed by scale, and a scale change produces no grid update
    // of its own, so force a rebuild.
    builtBounds = nil
    setNeedsDisplay(bounds)
  }

  private func makeRenderInput() -> GridRenderInput? {
    guard let grid = renderContext.state.grids[gridID] else {
      return nil
    }

    let upsideDownTransform = CGAffineTransform(scaleX: 1, y: -1)
      .translatedBy(x: 0, y: -bounds.height)

    return GridRenderInput(
      snapshot: .init(
        grid: grid,
        upsideDownTransform: upsideDownTransform,
        font: renderContext.state.font,
        appearance: renderContext.state.appearance,
        cursorBlinkingPhase: renderContext.state.cursorBlinkingPhase,
        isBusy: renderContext.state.isBusy,
        isApplicationActive: renderContext.state.isApplicationActive,
      ),
      updates: renderContext.updates,
      metalFrame: nil,
    )
  }
}
