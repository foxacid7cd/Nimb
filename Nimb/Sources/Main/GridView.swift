// SPDX-License-Identifier: MIT

import Algorithms
import AppKit
import NimbCore
import NimbNeovim
import NimbState

public class GridView: NSView, CALayerDelegate, Rendering {
  /// Most wheel events one NSEvent may turn into. A single event can carry a
  /// large delta, and each wheel event costs Neovim a redraw, so an uncapped
  /// burst becomes a backlog it spends seconds draining while the screen sits
  /// still. Past the cap the remainder is dropped rather than queued: falling
  /// behind the fingers is better than freezing.
  static let maxWheelEventsPerReport = 4

  /// Neovim's `mousescroll` defaults. Nimb does not read the option back, so
  /// changing it makes wheel tracking proportionally off.
  /// Lines of content per cell of finger travel. Tuned by feel: 1.0 tracks the
  /// fingers exactly but reads as sluggish, and the 2.4 this code effectively
  /// used before reads as slightly overshooting.
  private static let scrollLinesPerCell = 2.0
  /// Used while the fingers are down. Nimb owns `mousescroll` rather than
  /// reading it: the thresholds below are derived from it, so a value Nimb did
  /// not choose makes scroll speed wrong by that factor. AstroNvim sets
  /// ver:1,hor:2, for instance, which would put an event on the wire every
  /// half cell.
  private static let fineScrollLines = 3
  /// Used while the gesture coasts. Neovim redraws once per wheel event and
  /// runs its Lua decoration providers each time, so a scroll costs roughly
  /// what its event count costs, almost regardless of how far each event
  /// moves. Sampling a fast flick across every process put Neovim at 72% of a
  /// core inside decor_provider_invoke -> nlua_call_ref_ctx -> lua_pcall
  /// while Nimb sat at 12%, and the screen froze for up to 1.3s at a time.
  /// Coasting is where the events pile up and where precision does not
  /// matter, so each one carries four times the distance there.
  private static let coarseScrollLines = 12

  /// Columns of content per cell of finger travel. One to one, as before.
  private static let scrollColumnsPerCell = 1.0
  /// Twelve, not Neovim's default six: a horizontal wheel event costs a full
  /// viewport redraw, so halving the event count matters more than fine
  /// stepping. Paired with a twelve cell threshold this keeps the event rate
  /// the original code had while moving twice the distance per event.
  private static let fineScrollColumns = 12
  /// Horizontal scrolling changes every visible row rather than exposing a
  /// few new lines, so Neovim redraws the whole viewport and re-runs its decor
  /// providers over all of it. Measured on a heavily highlighted 190x50 view,
  /// one wheel event cost Neovim 62ms whether it moved 1 column or 30 -- the
  /// cost is per event, not per column, so it pinned a core at 15 columns a
  /// second. Thirty columns an event covers 355 columns a second for 26% more
  /// work per event. Coarse steps matter far more here than they do
  /// vertically.
  private static let coarseScrollColumns = 36

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
  private var isScrollingHorizontal: Bool? = nil
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
    layer!.addSublayer(gridLayer)

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

    // Coast on coarse steps, track finely while the fingers are down. Both
    // divide by the same lines-per-cell, so the scroll speed is identical
    // either way and only the granularity -- and so the number of redraws
    // Neovim has to run -- changes.
    let momentum = event.momentumPhase
    let isCoasting = momentum.contains(.began) || momentum.contains(.changed)
    let linesPerEvent = isCoasting ? Self.coarseScrollLines : Self.fineScrollLines
    let columnsPerEvent = isCoasting ? Self.coarseScrollColumns : Self.fineScrollColumns
    if linesPerEvent != scrollLinesPerEvent || columnsPerEvent != scrollColumnsPerEvent {
      scrollLinesPerEvent = linesPerEvent
      scrollColumnsPerEvent = columnsPerEvent
      // Ordered on the same channel as the wheel events below, so Neovim has
      // applied it before the events it applies to arrive.
      store.api.fastCall(APIFunctions.NvimSetOptionValue(
        name: "mousescroll",
        value: .string("ver:\(linesPerEvent),hor:\(columnsPerEvent)"),
        opts: .dictionary([:]),
      ))
    }

    let xThreshold = state.font.cellWidth * Double(columnsPerEvent) / Self.scrollColumnsPerCell
    let yThreshold = state.font.cellHeight * Double(linesPerEvent) / Self.scrollLinesPerCell

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

    if abs(xScrollingDelta) > xThreshold {
      let uncapped = Int(xScrollingDelta / xThreshold)
      horizontalScrollCount = uncapped.clampedToWheelBurst()
      if horizontalScrollCount == uncapped {
        xScrollingReported += xThreshold * Double(uncapped)
      } else {
        // Remainder dropped, so it cannot come back as a backlog.
        xScrollingReported = xScrollingAccumulator
      }
    }
    if abs(yScrollingDelta) > yThreshold {
      let uncapped = Int(yScrollingDelta / yThreshold)
      verticalScrollCount = uncapped.clampedToWheelBurst()
      if verticalScrollCount == uncapped {
        yScrollingReported += yThreshold * Double(uncapped)
      } else {
        yScrollingReported = yScrollingAccumulator
      }
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
            col: point.column,
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
            col: point.column,
          ),
        ].cycled(times: abs(verticalScrollCount))
      }

      for function in chain(horizontalScrollFunctions, verticalScrollFunctions) {
        store.api.fastCall(function)
      }
    }
  }

  public nonisolated func action(for layer: CALayer, forKey event: String) -> (any CAAction)? {
    NSNull()
  }

  public func render() {
    renderStats.count(.gridsVisited)
    let isCoreGraphics = state.debug.isCoreGraphicsRenderingEnabled

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

private extension Int {
  func clampedToWheelBurst() -> Int {
    Swift.max(-GridView.maxWheelEventsPerReport, Swift.min(GridView.maxWheelEventsPerReport, self))
  }
}
