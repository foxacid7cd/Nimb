// SPDX-License-Identifier: MIT

import AppKit
import CustomDump
import Library

public class GridView: NSView {
  public init(store: Store, id: Int, size: IntegerSize) {
    self.store = store
    grid = .init(id: id, size: size, font: store.font, appearance: store.appearance)
    super.init(frame: .init())
    clipsToBounds = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public var getNextWindowZIndex: (() -> Int)?
  public var gridConstraints: (horizontal: NSLayoutConstraint, vertical: NSLayoutConstraint, secondView: NSView, anchor: FloatingWindow.Anchor?)?

  override public var intrinsicContentSize: NSSize {
    grid.size * store.font.cellSize
  }

  public var zIndex: Double {
    grid.zIndex
  }

  override public var isOpaque: Bool {
    true
  }

  public var gridSize: IntegerSize {
    grid.size
  }

  public var gridWindow: Grid.AssociatedWindow? {
    grid.associatedWindow
  }

  public func apply(gridUpdate: State.GridUpdate) async throws {
    switch gridUpdate {
    case let .resize(size):
      let copyColumnsCount = min(grid.layout.columnsCount, size.columnsCount)
      let copyColumnsRange = 0 ..< copyColumnsCount
      let copyRowsCount = min(grid.layout.rowsCount, size.rowsCount)
      var cells = TwoDimensionalArray<Cell>(size: size, repeatingElement: .default)
      for row in 0 ..< copyRowsCount {
        cells.rows[row].replaceSubrange(
          copyColumnsRange,
          with: grid.layout.cells.rows[row][copyColumnsRange]
        )
      }
      grid.layout = .init(cells: cells)

      let cursorDrawRun = grid.drawRuns.cursorDrawRun
      grid.drawRuns = .init(layout: grid.layout, font: store.font, appearance: store.appearance)

      if
        let cursorDrawRun,
        cursorDrawRun.origin.column < size.columnsCount,
        cursorDrawRun.origin.row < size.rowsCount
      {
        grid.drawRuns.cursorDrawRun = cursorDrawRun
      }

      needsDisplay = true
    case .clear:
      grid.layout.cells = .init(size: grid.layout.cells.size, repeatingElement: .default)
      grid.layout.rowLayouts = grid.layout.cells.rows
        .map(RowLayout.init(rowCells:))
      grid.drawRuns.renderDrawRuns(for: grid.layout, font: store.font, appearance: store.appearance)

      needsDisplay = true
    case let .lines(lines):
      let grid = grid
      let font = store.font
      let appearance = store.appearance

      let results: [Grid.LineUpdatesResult] = if lines.count <= 15 {
        try applyLineUpdates(for: lines, grid: grid, font: font, appearance: appearance)
      } else {
        try await withThrowingTaskGroup(of: [Grid.LineUpdatesResult].self) { taskGroup in
          let lines = Array(lines)
          let chunkSize = lines.optimalChunkSize(preferredChunkSize: 15)
          for linesChunk in lines.chunks(ofCount: chunkSize) {
            taskGroup.addTask {
              try applyLineUpdates(for: linesChunk, grid: grid, font: font, appearance: appearance)
            }
          }

          var accumulator = [Grid.LineUpdatesResult]()
          accumulator.reserveCapacity(lines.count)
          for try await results in taskGroup {
            accumulator += results
          }

          return accumulator
        }
      }

      for result in results {
        self.grid.layout.cells.rows[result.row] = result.rowCells
        self.grid.layout.rowLayouts[result.row] = result.rowLayout
        self.grid.drawRuns.rowDrawRuns[result.row] = result.rowDrawRun

        if result.shouldUpdateCursorDrawRun {
          self.grid.drawRuns.cursorDrawRun!.updateParent(
            with: grid.layout,
            rowDrawRuns: grid.drawRuns.rowDrawRuns
          )
        }

        for dirtyRectangle in result.dirtyRectangles {
          setNeedsDisplay(dirtyRectangle)
        }
      }

      @Sendable func applyLineUpdates(
        for gridLines: some Sequence<(key: Int, value: [UIEventsChunk.GridLine])>,
        grid: Grid,
        font: Font,
        appearance: Appearance
      ) throws -> [Grid.LineUpdatesResult] {
        var accumulator = [Grid.LineUpdatesResult]()

        for (row, rowGridLines) in gridLines {
          var lineUpdates = [(originColumn: Int, cells: [Cell])]()

          for gridLine in rowGridLines {
            var cells = [Cell]()
            var highlightID = 0

            for value in gridLine.data {
              guard
                case let .array(arrayValue) = value,
                !arrayValue.isEmpty,
                case let .string(text) = arrayValue[0]
              else {
                throw Failure("invalid grid line cell value", value)
              }

              var repeatCount = 1

              if arrayValue.count > 1 {
                guard
                  case let .integer(newHighlightID) = arrayValue[1]
                else {
                  throw Failure("invalid grid line cell highlight value", arrayValue[1])
                }

                highlightID = newHighlightID

                if arrayValue.count > 2 {
                  guard
                    case let .integer(newRepeatCount) = arrayValue[2]
                  else {
                    throw Failure("invalid grid line cell repeat count value", arrayValue[2])
                  }

                  repeatCount = newRepeatCount
                }
              }

              let cell = Cell(text: text, highlightID: highlightID)
              for _ in 0 ..< repeatCount {
                cells.append(cell)
              }
            }

            lineUpdates.append((gridLine.originColumn, cells))
          }

          accumulator.append(
            grid.applying(
              lineUpdates: lineUpdates,
              forRow: row,
              font: font,
              appearance: appearance
            )
          )
        }

        return accumulator
      }
    case let .scroll(frame, offset):
      if offset.columnsCount != 0 {
        Loggers.problems.error("Horizontal scroll not supported")
      }

      var shouldUpdateCursorDrawRun = false

      let cellsCopy = grid.layout.cells
      let rowLayoutsCopy = grid.layout.rowLayouts
      let rowDrawRunsCopy = grid.drawRuns.rowDrawRuns

      let toRectangle = frame
        .applying(offset: -offset)
        .intersection(with: frame)

      for toRow in toRectangle.rows {
        let fromRow = toRow + offset.rowsCount

        if frame.size.columnsCount == grid.size.columnsCount {
          grid.layout.cells.rows[toRow] = cellsCopy.rows[fromRow]
          grid.layout.rowLayouts[toRow] = rowLayoutsCopy[fromRow]
          grid.drawRuns.rowDrawRuns[toRow] = rowDrawRunsCopy[fromRow]
        } else {
          grid.layout.cells.rows[toRow].replaceSubrange(
            frame.columns,
            with: cellsCopy.rows[fromRow][frame.columns]
          )
          grid.layout.rowLayouts[toRow] = .init(rowCells: grid.layout.cells.rows[toRow])
          grid.drawRuns.rowDrawRuns[toRow] = .init(
            row: toRow,
            layout: grid.layout.rowLayouts[toRow],
            font: store.font,
            appearance: store.appearance,
            old: grid.drawRuns.rowDrawRuns[toRow]
          )
        }

        if
          grid.drawRuns.cursorDrawRun != nil,
          grid.drawRuns.cursorDrawRun!.origin.row == toRow,
          frame.columns.contains(grid.drawRuns.cursorDrawRun!.origin.column)
        {
          shouldUpdateCursorDrawRun = true
        }
      }

      if shouldUpdateCursorDrawRun {
        grid.drawRuns.cursorDrawRun!.updateParent(with: grid.layout, rowDrawRuns: grid.drawRuns.rowDrawRuns)
      }

      setNeedsDisplay(toRectangle)

    case .destroy:
      break
    case let .winPos(windowID, frame):
      let zIndex = getNextWindowZIndex?() ?? {
        Loggers.problems.error("GridView.getNextWindowZIndex returned nil")
        return 0
      }()
      grid.associatedWindow = .plain(
        .init(
          id: windowID,
          origin: frame.origin,
          zIndex: zIndex
        )
      )
      isHidden = false

      if frame.size != grid.size {
        try await apply(gridUpdate: .resize(frame.size))
      }
    case let .winFloatPos(windowID, anchor, anchorGridID, anchorOrigin, isFocusable, _):
      let zIndex = getNextWindowZIndex?() ?? {
        Loggers.problems.error("GridView.getNextWindowZIndex returned nil")
        return 0
      }()
      grid.associatedWindow = .floating(
        .init(
          id: windowID,
          anchor: anchor,
          anchorGridID: anchorGridID,
          anchorRow: anchorOrigin.row,
          anchorColumn: anchorOrigin.column,
          isFocusable: isFocusable,
          zIndex: zIndex
        )
      )
      isHidden = false
    case .winExternalPos:
      isHidden = false
    case .winHide:
      isHidden = true
    case .winClose:
      isHidden = true
    }
  }

  public func applyGridCursorMove(from: IntegerPoint? = nil, to: IntegerPoint?) {
    if let from {
      let invalidRectangle = grid.drawRuns.cursorDrawRun?.rectangle ?? .init(
        origin: from,
        size: .init(columnsCount: 1, rowsCount: 1)
      )
      grid.drawRuns.cursorDrawRun = nil
      setNeedsDisplay(invalidRectangle)
    }
    if let to, let cursorStyle = store.state.currentCursorStyle {
      let cursorDrawRun = CursorDrawRun(
        layout: grid.layout,
        rowDrawRuns: grid.drawRuns.rowDrawRuns,
        origin: to,
        columnsCount: 1,
        style: cursorStyle,
        font: store.font,
        appearance: store.appearance
      )
      if let cursorDrawRun {
        grid.drawRuns.cursorDrawRun = cursorDrawRun
        setNeedsDisplay(cursorDrawRun.rectangle)
      }
    }
  }

  public func cursorBlinkingPhaseUpdated() {
    guard let cursorDrawRun = grid.drawRuns.cursorDrawRun else {
      return
    }
    setNeedsDisplay(cursorDrawRun.rectangle)
  }

  public func setNeedsDisplay(_ invalidRectangle: IntegerRectangle) {
    setNeedsDisplay(
      (invalidRectangle * store.font.cellSize)
        .applying(upsideDownTransform)
    )
  }

  override public func draw(_ dirtyRect: NSRect) {
    let context = NSGraphicsContext.current!.cgContext

    let boundingRect = IntegerRectangle(
      frame: dirtyRect.applying(upsideDownTransform),
      cellSize: store.font.cellSize
    )
    context.setShouldAntialias(false)
    grid.drawRuns.drawBackground(
      to: context,
      boundingRect: boundingRect,
      font: store.font,
      appearance: store.appearance,
      upsideDownTransform: upsideDownTransform
    )
    context.setShouldAntialias(true)
    grid.drawRuns.drawForeground(
      to: context,
      boundingRect: boundingRect,
      font: store.font,
      appearance: store.appearance,
      upsideDownTransform: upsideDownTransform
    )

    if
      store.state.cursorBlinkingPhase,
      store.state.isMouseUserInteractionEnabled,
      let cursorDrawRun = grid.drawRuns.cursorDrawRun,
      boundingRect.contains(cursorDrawRun.origin)
    {
      cursorDrawRun.draw(
        to: context,
        font: store.font,
        appearance: store.appearance,
        upsideDownTransform: upsideDownTransform
      )
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

    let xThreshold = store.font.cellWidth * 6
    let yThreshold = store.font.cellHeight * 3

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
      let point = point(for: event)
      Task {
        await store.reportScrollWheel(
          with: direction,
          modifier: event.modifierFlags
            .makeModifiers(isSpecialKey: false)
            .joined(),
          gridID: grid.id,
          point: point,
          count: count
        )
        await store.scheduleHideMsgShowsIfPossible()
      }
    }
  }

  public func reportMouseMove(for event: NSEvent) {
    guard store.state.isMouseUserInteractionEnabled, store.state.cmdlines.dictionary.isEmpty else {
      return
    }
    Task {
      await store.reportMouseMove(
        modifier: event.modifierFlags
          .makeModifiers(isSpecialKey: false)
          .joined(),
        gridID: grid.id,
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

  private var grid: Grid
  private let store: Store
  private var isScrollingHorizontal: Bool?
  private var xScrollingAccumulator: Double = 0
  private var yScrollingAccumulator: Double = 0

  private var upsideDownTransform: CGAffineTransform {
    .init(scaleX: 1, y: -1)
      .translatedBy(x: 0, y: -Double(grid.rowsCount) * store.font.cellHeight)
  }

  private func report(mouseButton: Instance.MouseButton, action: Instance.MouseAction, with event: NSEvent) {
    guard store.state.isMouseUserInteractionEnabled else {
      return
    }
    let point = point(for: event)
    Task {
      await store.report(
        mouseButton: mouseButton,
        action: action,
        modifier: event.modifierFlags
          .makeModifiers(isSpecialKey: false)
          .joined(),
        gridID: grid.id,
        point: point
      )
      await store.scheduleHideMsgShowsIfPossible()
    }
  }
}
