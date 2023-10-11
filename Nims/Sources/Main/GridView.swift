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
    drawRunsContainer = .init(
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
      if let cursor = store.cursor, cursor.gridID == gridID {
        cursorDrawRun = .init(
          rowDrawRuns: drawRunsContainer.rowDrawRuns,
          cursor: cursor,
          modeInfo: store.modeInfo,
          mode: store.mode,
          font: store.font,
          appearance: store.appearance
        )
        setNeedsDisplay((IntegerRectangle(origin: cursor.position, size: .init(columnsCount: 1, rowsCount: 1)) * store.font.cellSize).applying(upsideDownTransform))
      } else {
        cursorDrawRun = nil
        needsDisplay = true
      }
    }
  }

  public func render(textUpdates: [GridTextUpdate]) {
    for textUpdate in textUpdates {
      gridLayout.apply(textUpdate: textUpdate)

      drawRunsContainer.render(textUpdate: textUpdate, gridLayout: gridLayout, font: store.font, appearance: store.appearance)

      switch textUpdate {
      case .resize:
        needsDisplay = true

      case let .line(origin, cells):
        let rectangle = IntegerRectangle(origin: origin, size: .init(columnsCount: cells.count, rowsCount: 1))
        let rect = (rectangle * store.font.cellSize).applying(upsideDownTransform)
        setNeedsDisplay(rect)

      case let .scroll(rectangle, offset):
        let rectangle = IntegerRectangle(
          origin: .init(column: rectangle.origin.column, row: rectangle.origin.row + min(0, offset.rowsCount)),
          size: .init(
            columnsCount: rectangle.size.columnsCount,
            rowsCount: rectangle.maxRow - rectangle.minRow - min(0, offset.rowsCount) + max(0, offset.rowsCount)
          )
        )
        let rect = (rectangle * store.font.cellSize).applying(upsideDownTransform)
        setNeedsDisplay(rect)

      case .clear:
        needsDisplay = true
      }

//      switch textUpdate {
//      case let .redraw(rectangles):
//        if !rectangles.isEmpty {
//          for rectangle in rectangles {
//            let rect = (rectangle * store.font.cellSize)
//              .applying(upsideDownTransform)
//
//            setNeedsDisplay(rect)
//          }
//        } else {
//          needsDisplay = true
//        }
//
//      case let .scroll(rectangle, offset):
      ////        let rectangle = IntegerRectangle(
      ////          origin: .init(column: rectangle.origin.column, row: rectangle.origin.row + min(0, offset.rowsCount)),
      ////          size: .init(
      ////            columnsCount: rectangle.size.columnsCount,
      ////            rowsCount: rectangle.maxRow - rectangle.minRow - min(0, offset.rowsCount) + max(0, offset.rowsCount)
      ////          )
      ////        )
      ////        let rectangle1 = IntegerRectangle(origin: <#T##IntegerPoint#>, size: <#T##IntegerSize#>)
//        let rect = (rectangle * store.font.cellSize)
//          .applying(upsideDownTransform)
//
//        setNeedsDisplay(rect)
//        displayIfNeeded(rect)
//      }
    }
  }

  public func point(for gridPoint: IntegerPoint) -> CGPoint {
    (gridPoint * store.font.cellSize)
      .applying(upsideDownTransform)
  }

  override public func draw(_: NSRect) {
    guard let graphicsContext = NSGraphicsContext.current, let grid = store.grids[gridID] else {
      return
    }

    let cgContext = graphicsContext.cgContext

    var rectsPointer: UnsafePointer<NSRect>!
    var rectsCount = 0
    getRectsBeingDrawn(&rectsPointer, count: &rectsCount)

    var rects = [NSRect]()
    for rectIndex in 0 ..< rectsCount {
      let rect = rectsPointer
        .advanced(by: rectIndex)
        .pointee
      rects.append(rect)
    }

    for rect in rects {
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
      .intersection(with: .init(size: grid.size))

      // var drawRuns = [(origin: CGPoint, highlightID: Highlight.ID, drawRun: DrawRun)]()

//      graphicsContext.shouldAntialias = false
      drawRunsContainer.draw(
        to: cgContext,
        boundingRect: integerFrame,
        font: store.font,
        appearance: store.appearance,
        upsideDownTransform: upsideDownTransform
      )

      if
        let cursorDrawRun,
        (integerFrame.minColumn ..< integerFrame.maxColumn).contains(cursorDrawRun.position.column),
        (integerFrame.minRow ..< integerFrame.maxRow).contains(cursorDrawRun.position.row)
      {
        cursorDrawRun.draw(
          at: .init(x: 0, y: Double(cursorDrawRun.position.row) * store.font.cellSize.height)
            .applying(upsideDownTransform),
          to: cgContext,
          font: store.font,
          appearance: store.appearance,
          upsideDownTransform: upsideDownTransform
        )
      }
//      for row in integerFrame.rows {
//        if rowDrawRuns[row] == nil {
//          var rowDrawRun = RowDrawRun(origins: [], highlightIDs: [], drawRuns: [])
//          let rowLayout = grid.rowLayouts[row]
//
//          for part in rowLayout.parts {
//            let backgroundColor = store.appearance.backgroundColor(for: part.highlightID)
//
//            let partIntegerFrame = IntegerRectangle(
//              origin: .init(column: part.range.location, row: 0),
//              size: .init(columnsCount: part.range.length, rowsCount: 1)
//            )
//            let partFrame = partIntegerFrame * store.font.cellSize
//            let upsideDownPartFrame = partFrame
//              .applying(upsideDownTransform)
//
//            backgroundColor.appKit.setFill()
//            cgContext.fill([upsideDownPartFrame])
//
//            let drawRun = drawRunsProvider
//              .drawRun(
//                with: .init(
//                  integerSize: IntegerSize(
//                    columnsCount: part.range.length,
//                    rowsCount: 1
//                  ),
//                  text: part.text,
//                  font: store.font,
//                  isItalic: store.appearance.isItalic(for: part.highlightID),
//                  isBold: store.appearance.isBold(for: part.highlightID),
//                  decorations: store.appearance.decorations(for: part.highlightID)
//                )
//              )
//            rowDrawRun.origins.append(upsideDownPartFrame.origin)
//            rowDrawRun.highlightIDs.append(part.highlightID)
//            rowDrawRun.drawRuns.append(drawRun)
//
//            if
//              store.cursorBlinkingPhase,
//              let modeInfo = store.modeInfo,
//              let mode = store.mode,
//              let cursor = store.cursor,
//              cursor.gridID == gridID,
//              cursor.position.row == row,
//              cursor.position.column >= part.range.location,
//              cursor.position.column < part.range.location + part.range.length
//            {
//              let cursorStyle = modeInfo
//                .cursorStyles[mode.cursorStyleIndex]
//
//              if let cursorShape = cursorStyle.cursorShape {
//                let cursorFrame: CGRect
//                switch cursorShape {
//                case .block:
//                  let integerFrame = IntegerRectangle(
//                    origin: cursor.position,
//                    size: .init(columnsCount: 1, rowsCount: 1)
//                  )
//                  cursorFrame = integerFrame * store.font.cellSize
//
//                case .horizontal:
//                  let size = CGSize(
//                    width: store.font.cellWidth,
//                    height: store.font.cellHeight / 100.0 * Double(cursorStyle.cellPercentage ?? 25)
//                  )
//                  cursorFrame = .init(
//                    origin: .init(
//                      x: Double(cursor.position.column) * store.font.cellWidth,
//                      y: Double(cursor.position.row + 1) * store.font.cellHeight - size.height
//                    ),
//                    size: size
//                  )
//
//                case .vertical:
//                  let width = store.font.cellWidth / 100.0 * Double(cursorStyle.cellPercentage ?? 25)
//
//                  cursorFrame = CGRect(
//                    origin: cursor.position * store.font.cellSize,
//                    size: .init(width: width, height: store.font.cellHeight)
//                  )
//                }
//
//                let cursorUpsideDownFrame = cursorFrame
//                  .applying(upsideDownTransform)
//
//                let cursorHighlightID = cursorStyle.attrID ?? 0
//
//                cursorDrawRun = .init(
//                  frame: cursorUpsideDownFrame,
//                  highlightID: cursorHighlightID,
//                  parentOrigin: upsideDownPartFrame.origin,
//                  parentDrawRun: drawRun,
//                  parentHighlightID: part.highlightID
//                )
//              }
//            }
//          }
//
//          rowDrawRuns[row] = rowDrawRun
//        }
//      }

//      for row in 0 ..< grid.rowsCount {
//        let rowDrawRun = rowDrawRuns[row]!
//        for (drawRunIndex, drawRun) in rowDrawRun.drawRuns.enumerated() {
//          let origin = rowDrawRun.origins[drawRunIndex]
//          let highlightID = rowDrawRun.highlightIDs[drawRunIndex]
//          let foregroundColor = store.appearance.foregroundColor(for: highlightID)
//          let specialColor = store.appearance.specialColor(for: highlightID)
//
//          drawRun.draw(
//            at: origin + .init(x: 0, y: -Double(row) * store.font.cellHeight),
//            to: graphicsContext,
//            foregroundColor: foregroundColor,
//            specialColor: specialColor
//          )
//        }
//      }

//      if let cursorDrawRun {
//        graphicsContext.saveGraphicsState()
//
//        let cursorForegroundColor: NimsColor
//        let cursorBackgroundColor: NimsColor
//
//        if cursorDrawRun.highlightID == 0 {
//          cursorForegroundColor = store.appearance.backgroundColor(for: cursorDrawRun.parentHighlightID)
//          cursorBackgroundColor = store.appearance.foregroundColor(for: cursorDrawRun.parentHighlightID)
//
//        } else {
//          cursorForegroundColor = store.appearance.foregroundColor(for: cursorDrawRun.highlightID)
//          cursorBackgroundColor = store.appearance.backgroundColor(for: cursorDrawRun.highlightID)
//        }
//
//        cursorBackgroundColor.appKit.setFill()
//        cursorDrawRun.frame.fill()
//
//        cursorDrawRun.frame.clip()
//        cursorDrawRun.parentDrawRun.draw(
//          at: cursorDrawRun.parentOrigin,
//          to: graphicsContext,
//          foregroundColor: cursorForegroundColor,
//          specialColor: cursorBackgroundColor
//        )
//
//        graphicsContext.restoreGraphicsState()
//      }
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
  private let drawRunsContainer: DrawRunsContainer
  private var isScrollingHorizontal: Bool?
  private var xScrollingAccumulator: Double = 0
  private var yScrollingAccumulator: Double = 0
  private var trackingArea: NSTrackingArea?
  private var previousMouseMoveEvent: MouseEvent?
  private var cursorDrawRun: CursorDrawRun?

  private var upsideDownTransform: CGAffineTransform {
    .init(scaleX: 1, y: -1)
      .translatedBy(x: 0, y: -frame.height)
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
}
