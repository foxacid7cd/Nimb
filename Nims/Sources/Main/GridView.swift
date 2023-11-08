// SPDX-License-Identifier: MIT

import AppKit
import CustomDump
import Library

public class GridView: NSView {
  init(store: Store, gridID: Grid.ID) {
    self.store = store
    self.gridID = gridID
    super.init(frame: .init())
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public var windowConstraints: (leading: NSLayoutConstraint, top: NSLayoutConstraint)?
  public var floatingWindowConstraints: (horizontal: NSLayoutConstraint, vertical: NSLayoutConstraint)?

  override public var intrinsicContentSize: NSSize {
    grid.size * store.font.cellSize
  }

  public var zIndex: Double {
    grid.zIndex
  }

  override public var isOpaque: Bool {
    true
  }

  public func render(stateUpdates: State.Updates, gridUpdate: Grid.UpdateResult?) {
    var viewNeedsDisplay = false
    var dirtyRectangles = [IntegerRectangle]()

    if stateUpdates.isFontUpdated || stateUpdates.isAppearanceUpdated {
      viewNeedsDisplay = true
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
        dirtyRectangles += value

      case .needsDisplay:
        viewNeedsDisplay = true
      }
    }

    if viewNeedsDisplay {
      needsDisplay = true

    } else {
      for dirtyRectangle in dirtyRectangles {
        setNeedsDisplay(
          (dirtyRectangle * store.font.cellSize)
            .applying(upsideDownTransform)
        )
      }
    }

    displayIfNeeded()
  }

  override public func draw(_: NSRect) {
    let context = NSGraphicsContext.current!.cgContext

    var rectsPointer: UnsafePointer<NSRect>!
    var rectsCount = 0
    getRectsBeingDrawn(&rectsPointer, count: &rectsCount)

    for i in 0 ..< rectsCount {
      let rect = rectsPointer
        .advanced(by: i)
        .pointee
        .intersection(bounds)

      let upsideDownRect = rect
        .applying(upsideDownTransform)

      let integerFrame = IntegerRectangle(
        origin: .init(
          column: Int(upsideDownRect.origin.x / store.font.cellWidth),
          row: Int(upsideDownRect.origin.y / store.font.cellHeight)
        ),
        size: .init(
          columnsCount: Int(ceil(upsideDownRect.size.width / store.font.cellWidth)),
          rowsCount: Int(ceil(upsideDownRect.size.height / store.font.cellHeight))
        )
      )

      grid.drawRuns.draw(
        to: context,
        boundingRect: integerFrame,
        font: store.font,
        appearance: store.appearance,
        upsideDownTransform: upsideDownTransform
      )

      if
        store.state.cursorBlinkingPhase,
        store.state.isMouseUserInteractionEnabled,
        let cursorDrawRun = grid.drawRuns.cursorDrawRun,
        integerFrame.contains(cursorDrawRun.position)
      {
        cursorDrawRun.draw(
          to: context,
          font: store.font,
          appearance: store.appearance,
          upsideDownTransform: upsideDownTransform
        )
      }
    }
  }

  override public func mouseDown(with event: NSEvent) {
    report(mouseButton: .left, action: .press, with: event)
  }

  override public func mouseDragged(with event: NSEvent) {
    report(mouseButton: .left, action: .drag, with: event)
  }

  override public func mouseUp(with event: NSEvent) {
    report(mouseButton: .left, action: .release, with: event)
  }

  override public func rightMouseDown(with event: NSEvent) {
    report(mouseButton: .right, action: .press, with: event)
  }

  override public func rightMouseDragged(with event: NSEvent) {
    report(mouseButton: .right, action: .drag, with: event)
  }

  override public func rightMouseUp(with event: NSEvent) {
    report(mouseButton: .right, action: .release, with: event)
  }

  override public func otherMouseDown(with event: NSEvent) {
    report(mouseButton: .middle, action: .press, with: event)
  }

  override public func otherMouseDragged(with event: NSEvent) {
    report(mouseButton: .middle, action: .drag, with: event)
  }

  override public func otherMouseUp(with event: NSEvent) {
    report(mouseButton: .middle, action: .release, with: event)
  }

  override public func scrollWheel(with event: NSEvent) {
    guard store.state.isMouseUserInteractionEnabled, store.state.cmdlines.dictionary.isEmpty else {
      return
    }

    if event.phase == .began {
      isScrollingHorizontal = nil
      xScrollingAccumulator = 0
      yScrollingAccumulator = 0
    }

    xScrollingAccumulator -= event.scrollingDeltaX
    yScrollingAccumulator -= event.scrollingDeltaY

    let xThreshold = store.font.cellSize.width * 6
    let yThreshold = store.font.cellSize.height * 3

    var direction: Instance.ScrollDirection?
    var count = 0

    if isScrollingHorizontal != true, abs(yScrollingAccumulator) > yThreshold {
      if isScrollingHorizontal == nil {
        isScrollingHorizontal = false
      }

      count = Int(abs(yScrollingAccumulator) / yThreshold)
      let yScrollingToBeReported = yThreshold * Double(count)
      if yScrollingAccumulator > 0 {
        direction = .down
        yScrollingAccumulator -= yScrollingToBeReported
      } else {
        direction = .up
        yScrollingAccumulator += yScrollingToBeReported
      }

    } else if isScrollingHorizontal != false, abs(xScrollingAccumulator) > xThreshold {
      if isScrollingHorizontal == nil {
        isScrollingHorizontal = true
      }

      count = Int(abs(xScrollingAccumulator) / xThreshold)
      let xScrollingToBeReported = xThreshold * Double(count)
      if xScrollingAccumulator > 0 {
        direction = .right
        xScrollingAccumulator -= xScrollingToBeReported
      } else {
        direction = .left
        xScrollingAccumulator += xScrollingToBeReported
      }
    }

    if let direction, count > 0 {
      Task {
        await store.reportScrollWheel(
          with: direction,
          modifier: event.modifierFlags.makeModifier(isSpecialKey: false),
          gridID: gridID,
          point: point(for: event),
          count: count
        )
      }

      store.scheduleHideMsgShowsIfPossible()
    }
  }

  public func reportMouseMove(for event: NSEvent) {
    guard store.state.isMouseUserInteractionEnabled, store.state.cmdlines.dictionary.isEmpty else {
      return
    }
    Task {
      await store.reportMouseMove(
        modifier: event.modifierFlags.makeModifier(isSpecialKey: false),
        gridID: gridID,
        point: point(for: event)
      )
    }
  }

  public func point(for event: NSEvent) -> IntegerPoint {
    let upsideDownLocation = convert(event.locationInWindow, from: nil)
      .applying(upsideDownTransform)
    return .init(
      column: Int(upsideDownLocation.x / store.font.cellWidth),
      row: Int(upsideDownLocation.y / store.font.cellHeight)
    )
  }

  public func windowFrame(forGridFrame gridFrame: IntegerRectangle) -> CGRect {
    let viewFrame = (gridFrame * store.font.cellSize)
      .applying(upsideDownTransform)
    return convert(viewFrame, to: nil)
  }

  private let gridID: Grid.ID
  private let store: Store
  private var isScrollingHorizontal: Bool?
  private var xScrollingAccumulator: Double = 0
  private var yScrollingAccumulator: Double = 0

  private var grid: Grid {
    store.state.grids[gridID]!
  }

  private var upsideDownTransform: CGAffineTransform {
    .init(scaleX: 1, y: -1)
      .translatedBy(x: 0, y: -Double(grid.rowsCount) * store.font.cellHeight)
  }

  private func report(mouseButton: Instance.MouseButton, action: Instance.MouseAction, with event: NSEvent) {
    guard store.state.isMouseUserInteractionEnabled else {
      return
    }
    Task {
      await store.report(
        mouseButton: mouseButton,
        action: action,
        modifier: event.modifierFlags.makeModifier(isSpecialKey: false),
        gridID: gridID,
        point: point(for: event)
      )
    }
    store.scheduleHideMsgShowsIfPossible()
  }
}
