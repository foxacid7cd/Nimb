// SPDX-License-Identifier: MIT

import AppKit
import Library
import Neovim

public final class GridView: NSView {
  var font: NimsFont!
  var stateContainer: Neovim.Instance.StateContainer!
  var gridID: Neovim.Grid.ID!
  var reportMouseEvent: ((MouseEvent) -> Void)?

  var sizeConstraints: (width: NSLayoutConstraint, height: NSLayoutConstraint)?
  var windowConstraints: (leading: NSLayoutConstraint, top: NSLayoutConstraint)?
  var floatingWindowConstraints: (horizontal: NSLayoutConstraint, vertical: NSLayoutConstraint)?

  var state: Neovim.State {
    stateContainer.state
  }

  var ordinal: Double {
    stateContainer.state.grids[gridID]?.ordinal ?? -1
  }

  private let drawRunsProvider = DrawRunsProvider()

  override public func draw(_: NSRect) {
    guard let graphicsContext = NSGraphicsContext.current, let grid = state.grids[gridID] else {
      return
    }

    let cgContext = graphicsContext.cgContext

    cgContext.saveGState()
    defer { cgContext.restoreGState() }

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
      let upsideDownRect = CGRect(
        origin: .init(
          x: rect.origin.x,
          y: bounds.height - rect.origin.y - rect.size.height
        ),
        size: rect.size
      )

      let integerFrame = IntegerRectangle(
        origin: .init(
          column: Int(upsideDownRect.origin.x / font.cellWidth),
          row: Int(upsideDownRect.origin.y / font.cellHeight)
        ),
        size: .init(
          columnsCount: Int(ceil(upsideDownRect.size.width / font.cellWidth)),
          rowsCount: Int(ceil(upsideDownRect.size.height / font.cellHeight))
        )
      )
      .intersection(with: .init(size: grid.cells.size))

      var drawRuns = [(origin: CGPoint, highlightID: Highlight.ID, drawRun: DrawRun)]()
      var cursorDrawRun: CursorDrawRun?

      struct CursorDrawRun {
        internal init(
          frame: CGRect,
          highlightID: Highlight.ID,
          parentOrigin: CGPoint,
          parentDrawRun: DrawRun,
          parentHighlightID: Highlight.ID
        ) {
          self.frame = frame
          self.highlightID = highlightID
          self.parentOrigin = parentOrigin
          self.parentDrawRun = parentDrawRun
          self.parentHighlightID = parentHighlightID
        }

        var frame: CGRect
        var highlightID: Highlight.ID
        var parentOrigin: CGPoint
        var parentDrawRun: DrawRun
        var parentHighlightID: Highlight.ID
      }

      graphicsContext.shouldAntialias = false
      for row in integerFrame.rows {
        let rowLayout = grid.rowLayouts[row]

        for part in rowLayout.parts {
          let backgroundColor = state.backgroundColor(for: part.highlightID)

          let partIntegerFrame = IntegerRectangle(
            origin: .init(column: part.indices.lowerBound, row: row),
            size: .init(columnsCount: part.indices.count, rowsCount: 1)
          )
          let partFrame = partIntegerFrame * font.cellSize
          let upsideDownPartFrame = CGRect(
            origin: .init(
              x: partFrame.origin.x,
              y: bounds.height - partFrame.origin.y - font.cellHeight
            ),
            size: partFrame.size
          )

          backgroundColor.appKit.setFill()
          cgContext.fill([upsideDownPartFrame])

          let drawRun = drawRunsProvider
            .drawRun(
              with: .init(
                integerSize: IntegerSize(
                  columnsCount: part.indices.count,
                  rowsCount: 1
                ),
                text: part.text,
                font: font,
                isItalic: state.isItalic(for: part.highlightID),
                isBold: state.isBold(for: part.highlightID),
                decorations: state.decorations(for: part.highlightID)
              )
            )
          drawRuns.append(
            (
              origin: upsideDownPartFrame.origin,
              highlightID: part.highlightID,
              drawRun: drawRun
            )
          )

          if
            let modeInfo = state.modeInfo,
            let mode = state.mode,
//            model.cursorBlinkingPhase,
            let cursor = state.cursor,
            cursor.gridID == gridID,
            cursor.position.row == row,
            part.indices.contains(cursor.position.column)
          {
            let cursorStyle = modeInfo
              .cursorStyles[mode.cursorStyleIndex]

            if let cursorShape = cursorStyle.cursorShape {
              let cursorFrame: CGRect
              switch cursorShape {
              case .block:
                let integerFrame = IntegerRectangle(
                  origin: cursor.position,
                  size: .init(columnsCount: 1, rowsCount: 1)
                )
                cursorFrame = integerFrame * font.cellSize

              case .horizontal:
                let height = font.cellHeight / 100.0 * Double(cursorStyle.cellPercentage ?? 25)

                cursorFrame = CGRect(
                  x: Double(cursor.position.column) * font.cellWidth,
                  y: Double(cursor.position.row) * font.cellHeight,
                  width: font.cellWidth,
                  height: height
                )

              case .vertical:
                let width = font.cellWidth / 100.0 * Double(cursorStyle.cellPercentage ?? 25)

                cursorFrame = CGRect(
                  origin: cursor.position * font.cellSize,
                  size: .init(width: width, height: font.cellHeight)
                )
              }

              let cursorUpsideDownFrame = CGRect(
                origin: .init(
                  x: cursorFrame.origin.x,
                  y: bounds.height - cursorFrame.origin.y - font.cellHeight
                ),
                size: cursorFrame.size
              )

              let cursorHighlightID = cursorStyle.attrID ?? .default

              cursorDrawRun = .init(
                frame: cursorUpsideDownFrame,
                highlightID: cursorHighlightID,
                parentOrigin: upsideDownPartFrame.origin,
                parentDrawRun: drawRun,
                parentHighlightID: part.highlightID
              )
            }
          }
        }
      }

      for (origin, highlightID, drawRun) in drawRuns {
        let foregroundColor = state.foregroundColor(for: highlightID)
        let specialColor = state.specialColor(for: highlightID)

        drawRun.draw(
          at: origin,
          to: graphicsContext,
          foregroundColor: foregroundColor,
          specialColor: specialColor
        )
      }

      if let cursorDrawRun {
        graphicsContext.saveGraphicsState()

        let cursorForegroundColor: Neovim.Color
        let cursorBackgroundColor: Neovim.Color

        if cursorDrawRun.highlightID.isDefault {
          cursorForegroundColor = state.backgroundColor(for: cursorDrawRun.parentHighlightID)
          cursorBackgroundColor = state.foregroundColor(for: cursorDrawRun.parentHighlightID)

        } else {
          cursorForegroundColor = state.foregroundColor(for: cursorDrawRun.highlightID)
          cursorBackgroundColor = state.backgroundColor(for: cursorDrawRun.highlightID)
        }

        cursorBackgroundColor.appKit.setFill()
        cursorDrawRun.frame.fill()

        cursorDrawRun.frame.clip()
        cursorDrawRun.parentDrawRun.draw(
          at: cursorDrawRun.parentOrigin,
          to: graphicsContext,
          foregroundColor: cursorForegroundColor,
          specialColor: cursorBackgroundColor
        )

        graphicsContext.restoreGraphicsState()
      }
    }
  }

  override public func mouseDown(with event: NSEvent) {
    report(event, of: .mouse(button: .left, action: .press))
  }

  override public func mouseDragged(with event: NSEvent) {
    report(event, of: .mouse(button: .left, action: .drag))
  }

  override public func mouseUp(with event: NSEvent) {
    report(event, of: .mouse(button: .left, action: .release))
  }

  override public func rightMouseDown(with event: NSEvent) {
    report(event, of: .mouse(button: .right, action: .press))
  }

  override public func rightMouseDragged(with event: NSEvent) {
    report(event, of: .mouse(button: .right, action: .drag))
  }

  override public func rightMouseUp(with event: NSEvent) {
    report(event, of: .mouse(button: .right, action: .release))
  }

  override public func otherMouseDown(with event: NSEvent) {
    report(event, of: .mouse(button: .middle, action: .press))
  }

  override public func otherMouseDragged(with event: NSEvent) {
    report(event, of: .mouse(button: .middle, action: .drag))
  }

  override public func otherMouseUp(with event: NSEvent) {
    report(event, of: .mouse(button: .middle, action: .release))
  }

  private var isScrollingHorizontal: Bool?
  private var xScrollingAccumulator: Double = 0
  private var yScrollingAccumulator: Double = 0

  override public func scrollWheel(with event: NSEvent) {
    let cellSize = font.cellSize

    if event.phase == .began {
      isScrollingHorizontal = nil
      xScrollingAccumulator = 0
      yScrollingAccumulator = 0
    }

    xScrollingAccumulator -= event.scrollingDeltaX / 1.5
    yScrollingAccumulator -= event.scrollingDeltaY

    let xThreshold = cellSize.width * 3
    let yThreshold = cellSize.height * 3

    if isScrollingHorizontal != false {
      while abs(xScrollingAccumulator) > xThreshold {
        if isScrollingHorizontal == nil {
          isScrollingHorizontal = true
        }

        if xScrollingAccumulator > 0 {
          xScrollingAccumulator -= xThreshold
          report(event, of: .scrollWheel(direction: .right))

        } else {
          xScrollingAccumulator += xThreshold
          report(event, of: .scrollWheel(direction: .left))
        }
      }
    }

    if isScrollingHorizontal != true {
      while abs(yScrollingAccumulator) > yThreshold {
        if isScrollingHorizontal == nil {
          isScrollingHorizontal = false
        }

        if yScrollingAccumulator > 0 {
          yScrollingAccumulator -= yThreshold
          report(event, of: .scrollWheel(direction: .down))

        } else {
          yScrollingAccumulator += yThreshold
          report(event, of: .scrollWheel(direction: .up))
        }
      }
    }
  }

  private func report(_ nsEvent: NSEvent, of content: MouseEvent.Content) {
    let location = convert(nsEvent.locationInWindow, from: nil)
    let upsideDownLocation = CGPoint(
      x: location.x,
      y: bounds.height - location.y
    )
    let point = IntegerPoint(
      column: Int(upsideDownLocation.x / font.cellWidth),
      row: Int(upsideDownLocation.y / font.cellHeight)
    )
    reportMouseEvent?(.init(content: content, gridID: gridID, point: point))
  }
}
