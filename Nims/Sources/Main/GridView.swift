// SPDX-License-Identifier: MIT

import AppKit
import CustomDump
import Library

public enum GridTextUpdate: Sendable {
  case resize(IntegerSize)
  case line(origin: IntegerPoint, cells: [Cell])
  case scroll(rectangle: IntegerRectangle, offset: IntegerSize)
  case clear
}

public final class GridView: NSView {
  init(store: Store, gridID: Grid.ID) {
    self.store = store
    self.gridID = gridID
    let grid = store.grids[gridID]!
    gridLayout = .init(cells: .init(size: grid.size, repeatingElement: .default))
    gridDrawRuns = .init(
      gridLayout: gridLayout,
      font: store.font,
      appearance: store.appearance
    )
    super.init(frame: .init(origin: .init(), size: grid.size * store.font.cellSize))

    trackingArea = .init(
      rect: bounds,
      options: [.inVisibleRect, .activeInKeyWindow, .mouseMoved, .mouseEnteredAndExited],
      owner: self,
      userInfo: nil
    )
    addTrackingArea(trackingArea!)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public var intrinsicContentSize: NSSize {
    if case let .plain(window) = grid.associatedWindow {
      window.frame.size * store.font.cellSize
    } else {
      grid.size * store.font.cellSize
    }
  }

  public func render(stateUpdates: State.Updates) {
    if stateUpdates.isCursorUpdated {
      updateCursorDrawRun()
    } else if stateUpdates.isCursorBlinkingPhaseUpdated, let cursorDrawRun {
      setNeedsDisplay(cursorDrawRun.rectangle * store.font.cellSize)
    }
  }

  public func render(textUpdates: [GridTextUpdate]) {
    var dirtyRectangles: [IntegerRectangle]? = []

    for textUpdate in textUpdates {
      gridLayout.apply(textUpdate: textUpdate)

      gridDrawRuns.render(textUpdate: textUpdate, gridLayout: gridLayout, font: store.font, appearance: store.appearance)

      switch textUpdate {
      case .resize:
        dirtyRectangles = nil

      case let .line(origin, cells):
        let rectangle = IntegerRectangle(origin: origin, size: .init(columnsCount: cells.count, rowsCount: 1))
        if let cursorDrawRun, rectangle.intersects(with: cursorDrawRun.rectangle) {
          updateCursorDrawRun(display: false)
        }
        dirtyRectangles?.append(rectangle)

      case let .scroll(rectangle, offset):
        let rectangle = IntegerRectangle(
          origin: .init(column: rectangle.origin.column, row: rectangle.origin.row + min(0, offset.rowsCount)),
          size: .init(
            columnsCount: rectangle.size.columnsCount,
            rowsCount: rectangle.maxRow - rectangle.minRow - min(0, offset.rowsCount) + max(0, offset.rowsCount)
          )
        )
        if let cursorDrawRun, rectangle.intersects(with: cursorDrawRun.rectangle) {
          updateCursorDrawRun(display: false)
        }
        dirtyRectangles?.append(rectangle)

      case .clear:
        updateCursorDrawRun(display: false)
        dirtyRectangles = nil
      }
    }

    if let dirtyRectangles {
      for dirtyRectangle in dirtyRectangles {
        setNeedsDisplay(
          (dirtyRectangle * store.font.cellSize)
            .applying(upsideDownTransform)
        )
      }
    } else {
      needsDisplay = true
    }
  }

  public func point(for gridPoint: IntegerPoint) -> CGPoint {
    (gridPoint * store.font.cellSize)
      .applying(upsideDownTransform)
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
      .intersection(with: .init(size: gridLayout.cells.size))

      gridDrawRuns.draw(
        to: context,
        boundingRect: integerFrame,
        font: store.font,
        appearance: store.appearance,
        upsideDownTransform: upsideDownTransform
      )

      if
        store.cursorBlinkingPhase,
        let cursorDrawRun,
        (integerFrame.minColumn ..< integerFrame.maxColumn).contains(cursorDrawRun.position.column),
        (integerFrame.minRow ..< integerFrame.maxRow).contains(cursorDrawRun.position.row)
      {
        cursorDrawRun.draw(
          at: .init(x: 0, y: Double(cursorDrawRun.position.row) * store.font.cellSize.height),
          to: context,
          font: store.font,
          appearance: store.appearance,
          upsideDownTransform: upsideDownTransform
        )
      }
    }
  }

  override public func mouseDown(with event: NSEvent) {
    report(event, of: [.mouseButton(.left, action: .press)])
  }

  override public func mouseDragged(with event: NSEvent) {
    report(event, of: [.mouseButton(.left, action: .drag)])
  }

  override public func mouseUp(with event: NSEvent) {
    report(event, of: [.mouseButton(.left, action: .release)])
  }

  override public func rightMouseDown(with event: NSEvent) {
    report(event, of: [.mouseButton(.right, action: .press)])
  }

  override public func rightMouseDragged(with event: NSEvent) {
    report(event, of: [.mouseButton(.right, action: .drag)])
  }

  override public func rightMouseUp(with event: NSEvent) {
    report(event, of: [.mouseButton(.right, action: .release)])
  }

  override public func otherMouseDown(with event: NSEvent) {
    report(event, of: [.mouseButton(.middle, action: .press)])
  }

  override public func otherMouseDragged(with event: NSEvent) {
    report(event, of: [.mouseButton(.middle, action: .drag)])
  }

  override public func otherMouseUp(with event: NSEvent) {
    report(event, of: [.mouseButton(.middle, action: .release)])
  }

  override public func mouseMoved(with event: NSEvent) {
    report(event, of: [.mouseMove])
  }

  override public func mouseExited(with event: NSEvent) {
    previousMouseMoveEvent = nil
  }

  override public func scrollWheel(with event: NSEvent) {
    let cellSize = store.font.cellSize

    if event.phase == .began {
      isScrollingHorizontal = nil
      xScrollingAccumulator = 0
      yScrollingAccumulator = 0
    }

    xScrollingAccumulator -= event.scrollingDeltaX
    yScrollingAccumulator -= event.scrollingDeltaY

    let xThreshold = cellSize.width * 3
    let yThreshold = cellSize.height * 3

    var mouseEventContents = [MouseEvent.Content]()

    if isScrollingHorizontal != true {
      while abs(yScrollingAccumulator) > yThreshold {
        if isScrollingHorizontal == nil {
          isScrollingHorizontal = false
        }

        if yScrollingAccumulator > 0 {
          mouseEventContents.append(.scrollWheel(direction: .down))
          yScrollingAccumulator -= yThreshold
        } else {
          mouseEventContents.append(.scrollWheel(direction: .up))
          yScrollingAccumulator += yThreshold
        }
      }
    }

    if isScrollingHorizontal != false {
      while abs(xScrollingAccumulator) > xThreshold {
        if isScrollingHorizontal == nil {
          isScrollingHorizontal = true
        }

        if xScrollingAccumulator > 0 {
          mouseEventContents.append(.scrollWheel(direction: .right))
          xScrollingAccumulator -= xThreshold
        } else {
          mouseEventContents.append(.scrollWheel(direction: .left))
          xScrollingAccumulator += xThreshold
        }
      }
    }

    if !mouseEventContents.isEmpty {
      report(event, of: mouseEventContents)
    }
  }

  var windowConstraints: (leading: NSLayoutConstraint, top: NSLayoutConstraint)?
  var floatingWindowConstraints: (horizontal: NSLayoutConstraint, vertical: NSLayoutConstraint)?

  var ordinal: Double {
    store.grids[gridID]?.ordinal ?? -1
  }

  private let store: Store
  private let gridID: Grid.ID
  private var gridLayout: GridLayout
  private let gridDrawRuns: GridDrawRuns
  private var isScrollingHorizontal: Bool?
  private var xScrollingAccumulator: Double = 0
  private var yScrollingAccumulator: Double = 0
  private var trackingArea: NSTrackingArea?
  private var previousMouseMoveEvent: MouseEvent?
  private var cursorDrawRun: CursorDrawRun?

  private var upsideDownTransform: CGAffineTransform {
    .init(scaleX: 1, y: -1)
      .translatedBy(x: 0, y: -Double(gridLayout.size.rowsCount) * store.font.cellHeight)
  }

  private var grid: Grid {
    store.grids[gridID]!
  }

  private func report(_ nsEvent: NSEvent, of contents: [MouseEvent.Content]) {
    let upsideDownLocation = convert(nsEvent.locationInWindow, from: nil)
      .applying(upsideDownTransform)
    let point = IntegerPoint(
      column: Int(upsideDownLocation.x / store.font.cellWidth),
      row: Int(upsideDownLocation.y / store.font.cellHeight)
    )

    let modifier = nsEvent.modifierFlags.makeModifier(isSpecialKey: false) ?? ""
    let mouseEvents = contents
      .map { content in
        MouseEvent(content: content, gridID: gridID, point: point, modifier: modifier)
      }

    var filteredMouseEvents = [MouseEvent]()
    var shouldHideMsgShows = false

    for mouseEvent in mouseEvents {
      switch mouseEvent.content {
      case .mouseMove:
        if mouseEvent.point != previousMouseMoveEvent?.point {
          filteredMouseEvents.append(mouseEvent)
          previousMouseMoveEvent = mouseEvent
        }

      default:
        shouldHideMsgShows = true

        filteredMouseEvents.append(mouseEvent)
      }
    }

    if shouldHideMsgShows {
      store.scheduleHideMsgShowsIfPossible()
    }

    Task {
      await store.instance.report(mouseEvents: filteredMouseEvents)
    }
  }

  private func updateCursorDrawRun(display: Bool = true) {
    if 
      let cursor = store.cursor,
      cursor.gridID == gridID,
      let mode = store.mode,
      let modeInfo = store.modeInfo
    {
      let cursorStyle = modeInfo.cursorStyles[mode.cursorStyleIndex]
      cursorDrawRun = .init(
        gridLayout: gridLayout,
        rowDrawRuns: gridDrawRuns.rowDrawRuns,
        cursorPosition: cursor.position,
        cursorStyle: cursorStyle,
        font: store.font,
        appearance: store.appearance
      )
      if display {
        setNeedsDisplay((cursorDrawRun!.rectangle * store.font.cellSize).applying(upsideDownTransform))
      }
    } else {
      if let cursorDrawRun {
        self.cursorDrawRun = nil
        if display {
          setNeedsDisplay((cursorDrawRun.rectangle * store.font.cellSize).applying(upsideDownTransform))
        }
      }
    }
  }
}
