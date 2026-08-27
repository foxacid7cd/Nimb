// SPDX-License-Identifier: MIT

import Algorithms
import AppKit
import NimbCore
import NimbNeovim
import NimbState

public class GridView: NSView, CALayerDelegate, Rendering {
  /// Which way the current gesture has committed to, if it has.
  ///
  /// AppKit scroll views pin a gesture to one axis once it is clearly going
  /// that way, which is why a slightly crooked swipe in Safari scrolls
  /// straight down rather than drifting sideways. Fingers are not precise
  /// enough to keep a long vertical swipe perfectly vertical, and without
  /// this the sideways component accumulates until it is worth a column and
  /// the view slides.
  private enum ScrollAxis {
    /// Not enough travel yet to tell.
    case undecided
    case vertical
    case horizontal
    /// Deliberately diagonal, so neither axis is suppressed.
    case free
  }

  /// Most lines or columns one wheel event may ask Neovim to scroll. Past
  /// this the remainder is dropped rather than queued, so a hard flick cannot
  /// commit the screen to a redraw that takes seconds.
  static let maxScrollStep = 15

  /// How far a gesture must travel before it is pinned to an axis. Small
  /// enough that the decision is made early in the swipe, large enough that
  /// the very first event -- which is mostly noise -- does not decide it.
  private static let scrollAxisLockThreshold = 6.0

  /// How much one axis must lead the other to pin the gesture. A crooked
  /// vertical swipe runs about ten to one, so this only lets a genuinely
  /// diagonal gesture through unpinned.
  private static let scrollAxisLockRatio = 2.0

  /// Lines of content per cell of finger travel. Tuned by feel: 1.0 tracks the
  /// fingers exactly but reads as sluggish, and the 2.4 this code effectively
  /// used before reads as slightly overshooting.
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
  /// nil until the first render, so the first pass always applies visibility.
  private var renderingMode: Bool? = nil
  /// The bounds the last frame was built for. A resize changes every rect in
  /// the scene without producing a grid update, so it has to be tracked here
  /// rather than inferred from State.Updates. nil means nothing has been built.
  private var builtBounds: CGRect? = nil
  private let metalSceneBuilder: GridMetalSceneBuilder?
  /// What the state says about this grid's visibility, kept apart from
  /// whether the view has anything to show yet.
  private var isHiddenByState = false
  /// Whether the Metal layer has a frame to draw yet.
  ///
  /// A CAMetalLayer has no drawable until it presents, and scene building is
  /// asynchronous, so a newly created grid is composited before its first
  /// frame exists -- which is a hole, not a background, since the layer is not
  /// opaque. Showing a new grid only once it has drawn costs it one frame and
  /// removes the flash.
  private var hasPresentedFrame = false

  private var scrollAxis: ScrollAxis = .undecided
  private var xScrollingAccumulator: Double = 0
  private var xScrollingReported: Double = 0
  private var yScrollingAccumulator: Double = 0
  private var yScrollingReported: Double = 0
  private var previousMouseMove: (modifier: String, point: IntegerPoint)? = nil

  /// Mirrors what `mousescroll` was last set to, so the option is only pushed
  /// when it actually changes rather than on every wheel event.
  ///
  /// Starts at zero rather than the fine values so the first wheel event
  /// always pushes them. Assuming Neovim already agreed left the mirror wrong
  /// whenever the config set `mousescroll` itself, and scroll speed was off by
  /// that ratio until the first momentum flick happened to correct it.
  private var scrollLinesPerEvent = 0
  private var scrollColumnsPerEvent = 0

  public var grid: Grid? {
    guard isRendered else {
      return nil
    }
    return state.grids[gridID]
  }

  private var upsideDownTransform: CGAffineTransform? {
    guard let grid else {
      return nil
    }
    return .init(scaleX: 1, y: -1)
      .translatedBy(x: 0, y: -Double(grid.rowsCount) * state.font.cellHeight)
  }

  /// Whether this frame can change what this grid looks like.
  ///
  /// GridsView renders every grid view every frame, and a grid used to rebuild
  /// its whole Metal scene each time regardless of whether anything in it
  /// moved -- so a window with six splits paid six full scene builds to show
  /// one changed line. Both layers keep what they last drew (the Metal one
  /// keeps its last presented drawable, the CoreGraphics one its backing
  /// store), so returning false here leaves the correct pixels on screen.
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
    if updates.isMouseUserInteractionEnabledUpdated || updates.isCursorBlinkingPhaseUpdated {
      return true
    }
    // Content, scroll, clear and both halves of a cursor move all arrive here,
    // the last two because ApplyUIEvents issues .clearCursor to the old grid
    // and .cursor to the new one.
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

  /// Backing scale can change without the view changing window: dragging
  /// between a Retina and a non-Retina display, or changing a display's scaled
  /// resolution. Tracking it only in viewWillMove left contentsScale stale,
  /// and the Metal path takes that value as gospel -- it is the scale glyphs
  /// are rasterised at and the multiplier the drawable is sized by, so a stale
  /// one means every glyph bitmap is built for the wrong pixel density and
  /// then resampled. The CoreGraphics path never noticed, because it draws
  /// through CoreText afresh every time.
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

  override public func mouseDown(with event: NSEvent) {
    report(mouseButton: "left", action: "press", with: event)
  }

  override public func mouseDragged(with event: NSEvent) {
    report(mouseButton: "left", action: "drag", with: event)
  }

  override public func mouseUp(with event: NSEvent) {
    report(mouseButton: "left", action: "release", with: event)
  }

  override public func rightMouseDown(with event: NSEvent) {
    report(mouseButton: "right", action: "press", with: event)
  }

  override public func rightMouseDragged(with event: NSEvent) {
    report(mouseButton: "right", action: "drag", with: event)
  }

  override public func rightMouseUp(with event: NSEvent) {
    report(mouseButton: "right", action: "release", with: event)
  }

  override public func otherMouseDown(with event: NSEvent) {
    report(mouseButton: "middle", action: "press", with: event)
  }

  override public func otherMouseDragged(with event: NSEvent) {
    report(mouseButton: "middle", action: "drag", with: event)
  }

  override public func otherMouseUp(with event: NSEvent) {
    report(mouseButton: "middle", action: "release", with: event)
  }

  override public func scrollWheel(with event: NSEvent) {
    guard
      state.isMouseUserInteractionEnabled,
      state.cmdlines.dictionary.isEmpty
    else {
      return
    }

    // One wheel event to Neovim per gesture step, with the distance carried
    // by `mousescroll` rather than by repeating the event.
    //
    // A redraw costs Neovim the same whether it scrolls one line or thirty --
    // measured at 62ms either way on a heavily highlighted view -- so the
    // number of events is what the screen pays, not the distance they cover.
    // Sending the distance as an option and the step as a single event is how
    // VimR does it, and it is why the same configuration feels smoother
    // there: the old code here repeated the event up to four times to cover
    // the same travel, buying four redraws where one would do.
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

    // Kept in step with the editor background so that any moment the drawable
    // does not cover -- before the first frame, or a gap during a resize --
    // shows the right colour instead of nothing.
    if updates.isAppearanceUpdated || !hasPresentedFrame {
      gridLayer.setBackground(state.appearance.defaultBackgroundColor)
    }

    // The readiness gate only applies to the Metal layer, which is the one
    // that has nothing to show until it presents. The CoreGraphics layer
    // draws inside display(), so it is never blank -- and without this the
    // view would wait for a Metal frame that is never coming and stay hidden
    // for good.
    if isCoreGraphics || metalSceneBuilder == nil {
      markPresented()
    }

    // Compared against the mode actually in effect rather than against
    // updates.isDebugUpdated, which is false on the first render: the flag is
    // restored into the initial state rather than toggled into it, so keying
    // off the update left both layers in their constructed visibility and the
    // grid blank.
    let didSwitchRenderingMode = renderingMode != isCoreGraphics
    if didSwitchRenderingMode {
      renderingMode = isCoreGraphics
      // Each layer keeps whatever it last drew, so the one being switched away
      // from would otherwise stay on screen. Hide it and make the incoming one
      // repaint from scratch.
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

    // The CoreGraphics path stays synchronous. It shapes nothing up front --
    // all its work happens inside draw(in:), which CoreAnimation already calls
    // off the render loop -- and it is the control the Metal path is measured
    // against, so moving it would make the comparison meaningless.
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
    guard
      state.isMouseUserInteractionEnabled,
      state.cmdlines.dictionary.isEmpty
    else {
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
      column: Int(upsideDownLocation.x / state.font.cellWidth),
      row: Int(upsideDownLocation.y / state.font.cellHeight),
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

    // The atlas is keyed by scale, so the next build picks up a correctly
    // rasterised one -- but only if something asks for a rebuild, and a scale
    // change produces no grid update of its own.
    builtBounds = nil
    setNeedsDisplay(bounds)
  }

  private func makeRenderInput() -> GridRenderInput? {
    guard let grid = renderContext.state.grids[gridID] else {
      return nil
    }

    let upsideDownTransform = CGAffineTransform(scaleX: 1, y: -1)
      .translatedBy(x: 0, y: -Double(grid.rowsCount) * renderContext.state.font.cellHeight)

    return GridRenderInput(
      snapshot: .init(
        grid: grid,
        upsideDownTransform: upsideDownTransform,
        font: renderContext.state.font,
        appearance: renderContext.state.appearance,
        cursorBlinkingPhase: renderContext.state.cursorBlinkingPhase,
        isMouseUserInteractionEnabled: renderContext.state.isMouseUserInteractionEnabled,
      ),
      updates: renderContext.updates,
      metalFrame: nil,
    )
  }
}
