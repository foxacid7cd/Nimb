// SPDX-License-Identifier: MIT

import AppKit
import CasePaths
import Collections
import Combine
import ComposableArchitecture
import IdentifiedCollections
import Library
import Neovim
import Overture
import SwiftUI

@MainActor
public struct GridView: NSViewRepresentable {
  public init(
    gridID: Grid.ID,
    font: Font,
    highlights: IdentifiedArrayOf<Highlight>,
    defaultForegroundColor: Color,
    defaultBackgroundColor: Color,
    defaultSpecialColor: Color,
    store: StoreOf<Instance>,
    mouseEventHandler: @escaping (MouseEvent) -> Void
  ) {
    self.gridID = gridID
    self.font = font
    self.highlights = highlights
    self.defaultForegroundColor = defaultForegroundColor
    self.defaultBackgroundColor = defaultBackgroundColor
    self.defaultSpecialColor = defaultSpecialColor
    self.store = store
    self.mouseEventHandler = mouseEventHandler
  }

  @MainActor
  public class NSView: AppKit.NSView {
    override public func draw(_: NSRect) {
      guard let graphicsContext = NSGraphicsContext.current, let gridView, let state else {
        return
      }
      let cgContext = graphicsContext.cgContext
      let grid = state.grids[id: gridView.gridID]!

      graphicsContext.saveGraphicsState()
      defer { graphicsContext.restoreGraphicsState() }

      var rects: UnsafePointer<NSRect>!
      var rectsCount = 0
      getRectsBeingDrawn(&rects, count: &rectsCount)

      for rectIndex in 0 ..< rectsCount {
        let rect = rects.advanced(by: rectIndex).pointee

        let integerFrame = IntegerRectangle(
          origin: .init(
            column: Int(rect.origin.x / gridView.font.cellWidth),
            row: Int(rect.origin.y / gridView.font.cellHeight)
          ),
          size: .init(
            columnsCount: Int(ceil(rect.size.width / gridView.font.cellWidth)),
            rowsCount: Int(ceil(rect.size.height / gridView.font.cellHeight))
          )
        )
        let columnsRange = integerFrame.origin.column ..< integerFrame.origin.column + integerFrame.size.columnsCount

        for rowOffset in 0 ..< integerFrame.size.rowsCount {
          let row = integerFrame.origin.row + rowOffset

          guard row < grid.cells.size.rowsCount else {
            continue
          }

          let rowLayout = grid.rowLayouts[row]
          for part in rowLayout.parts where part.indices.overlaps(columnsRange) {
            let highlight = gridView.highlights[id: part.highlightID]
            let backgroundColor = highlight?.backgroundColor ?? gridView.defaultBackgroundColor
            let foregroundColor = highlight?.foregroundColor ?? gridView.defaultForegroundColor

            let partIntegerFrame = IntegerRectangle(
              origin: .init(column: part.indices.lowerBound, row: row),
              size: .init(columnsCount: part.indices.count, rowsCount: 1)
            )
            let partFrame = partIntegerFrame * gridView.font.cellSize
            let upsideDownPartFrame = CGRect(
              origin: .init(
                x: partFrame.origin.x,
                y: bounds.height - partFrame.origin.y - gridView.font.cellHeight
              ),
              size: partFrame.size
            )

            cgContext.setFillColor(backgroundColor.appKit.cgColor)
            cgContext.fill([upsideDownPartFrame])

            let attributedString = NSAttributedString(
              string: part.text,
              attributes: [.font: gridView.font.appKit]
            )

            let typesetter = CTTypesetterCreateWithAttributedString(attributedString)
            let line = CTTypesetterCreateLine(typesetter, .init(location: 0, length: 0))
            let runs = CTLineGetGlyphRuns(line) as! [CTRun]

            var drawRuns = [([CGPoint], [CGGlyph], CGAffineTransform)]()

            for run in runs {
              let glyphCount = CTRunGetGlyphCount(run)

              let glyphPositions = [CGPoint](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
                CTRunGetPositions(run, .init(location: 0, length: 0), buffer.baseAddress!)
                initializedCount = glyphCount
              }
              .map {
                CGPoint(
                  x: $0.x + upsideDownPartFrame.origin.x,
                  y: $0.y + upsideDownPartFrame.origin.y - gridView.font.appKit.descender
                )
              }

              let glyphs = [CGGlyph](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
                CTRunGetGlyphs(run, .init(location: 0, length: 0), buffer.baseAddress!)
                initializedCount = glyphCount
              }

              drawRuns.append((glyphPositions, glyphs, CTRunGetTextMatrix(run)))
            }

            for (glyphPositions, glyphs, textMatrix) in drawRuns {
              cgContext.textMatrix = textMatrix
              cgContext.setFillColor(foregroundColor.appKit.cgColor)
              CTFontDrawGlyphs(
                gridView.font.appKit,
                glyphs, glyphPositions,
                glyphs.count,
                cgContext
              )
            }

            if
              let cursor = state.cursor,
              cursor.gridID == gridView.gridID,
              cursor.position.row == row,
              part.indices.contains(cursor.position.column)
            {
              let cursorIntegerFrame = IntegerRectangle(
                origin: cursor.position,
                size: .init(columnsCount: 1, rowsCount: 1)
              )
              let cursorFrame = cursorIntegerFrame * gridView.font.cellSize
              let cursorUpsideDownFrame = CGRect(
                origin: .init(
                  x: cursorFrame.origin.x,
                  y: bounds.height - cursorFrame.origin.y - gridView.font.cellSize.height
                ),
                size: cursorFrame.size
              )

              cgContext.setFillColor(.white)
              cgContext.fill([cursorUpsideDownFrame])

              cgContext.saveGState()
              cgContext.clip(to: [cursorUpsideDownFrame])

              for (glyphPositions, glyphs, textMatrix) in drawRuns {
                cgContext.textMatrix = textMatrix
                cgContext.setFillColor(.black)
                CTFontDrawGlyphs(
                  gridView.font.appKit,
                  glyphs, glyphPositions,
                  glyphs.count,
                  cgContext
                )
              }

              cgContext.restoreGState()
            }
          }
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

    override public func scrollWheel(with event: NSEvent) {
      guard let gridView else {
        return
      }

      let yThreshold = gridView.font.cellHeight
      let xThreshold = gridView.font.cellWidth * 2

      if event.phase == .began {
        xScrollingAccumulator = 0
        yScrollingAccumulator = 0
        isScrollingHorizontal = nil
      }

      xScrollingAccumulator += event.scrollingDeltaX
      yScrollingAccumulator += event.scrollingDeltaY

      if isScrollingHorizontal == nil {
        if abs(yScrollingAccumulator) >= yThreshold {
          isScrollingHorizontal = false

        } else if abs(xScrollingAccumulator) >= xThreshold * 2 {
          isScrollingHorizontal = true
        }
      }

      if let isScrollingHorizontal {
        if isScrollingHorizontal {
          if xScrollingAccumulator > xThreshold {
            report(event, of: .scrollWheel(direction: .left))
            xScrollingAccumulator -= xThreshold

          } else if xScrollingAccumulator < -xThreshold {
            report(event, of: .scrollWheel(direction: .right))
            xScrollingAccumulator += xThreshold
          }

        } else {
          if yScrollingAccumulator > yThreshold {
            report(event, of: .scrollWheel(direction: .up))
            yScrollingAccumulator -= yThreshold

          } else if yScrollingAccumulator < -yThreshold {
            report(event, of: .scrollWheel(direction: .down))
            yScrollingAccumulator += yThreshold
          }
        }
      }
    }

    var gridView: GridView? {
      didSet {
        cancellable?.cancel()
        cancellable = nil

        if let gridView {
          let viewStore = ViewStore(
            gridView.store,
            observe: { $0 },
            removeDuplicates: {
              $0.gridUpdateFlags[gridView.gridID] == $1.gridUpdateFlags[gridView.gridID]
            }
          )

          cancellable = viewStore.publisher
            .sink { [weak self] state in
              self?.render(gridView: gridView, state: state)
            }
        }
      }
    }

    private var cancellable: AnyCancellable?
    private var state: Instance.State?
    private var xScrollingAccumulator: Double = 0
    private var yScrollingAccumulator: Double = 0
    private var isScrollingHorizontal: Bool?

    private func render(gridView: GridView, state: Instance.State) {
      self.state = state

      setNeedsDisplay(bounds)
    }

    private func report(_ nsEvent: NSEvent, of content: MouseEvent.Content) {
      guard let gridView else {
        return
      }

      let location = convert(nsEvent.locationInWindow, from: nil)
      let upsideDownLocation = CGPoint(
        x: location.x,
        y: bounds.height - location.y
      )
      let point = IntegerPoint(
        column: Int(upsideDownLocation.x / gridView.font.cellWidth),
        row: Int(upsideDownLocation.y / gridView.font.cellHeight)
      )
      let event = MouseEvent(content: content, gridID: gridView.gridID, point: point)
      gridView.mouseEventHandler(event)
    }
  }

  public var gridID: Grid.ID
  public var font: Font
  public var highlights: IdentifiedArrayOf<Highlight>
  public var defaultForegroundColor: Color
  public var defaultBackgroundColor: Color
  public var defaultSpecialColor: Color
  public var store: StoreOf<Instance>
  public var mouseEventHandler: (MouseEvent) -> Void

  public func makeNSView(context: Context) -> NSView {
    let view = NSView()
    view.gridView = self
    return view
  }

  public func updateNSView(_ nsView: NSView, context: Context) {
    nsView.gridView = self
  }
}
