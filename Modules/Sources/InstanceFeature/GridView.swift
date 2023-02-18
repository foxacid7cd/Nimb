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
public struct GridView: View {
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
  public struct HostingView: NSViewRepresentable {
    @Environment(\.drawRunCache)
    private var drawRunCache: DrawRunCache

    public var gridView: GridView

    public func makeNSView(context: Context) -> NSView {
      let view = NSView()
      view.data = (drawRunCache, gridView)
      return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
      nsView.data = (drawRunCache, gridView)
    }
  }

  @MainActor
  public class NSView: AppKit.NSView {
    override public func draw(_: NSRect) {
      guard let graphicsContext = NSGraphicsContext.current, let data, let state else {
        return
      }

      let drawRunCache = data.drawRunCache
      let gridView = data.gridView
      let cgContext = graphicsContext.cgContext
      let grid = state.grids[id: gridView.gridID]!

      cgContext.saveGState()
      defer { cgContext.restoreGState() }

      var rects: UnsafePointer<NSRect>!
      var rectsCount = 0
      getRectsBeingDrawn(&rects, count: &rectsCount)

      for rectIndex in 0 ..< rectsCount {
        let rect = rects.advanced(by: rectIndex).pointee
        let upsideDownRect = CGRect(
          origin: .init(
            x: rect.origin.x,
            y: bounds.height - rect.origin.y - rect.size.height
          ),
          size: rect.size
        )

        let integerFrame = IntegerRectangle(
          origin: .init(
            column: Int(upsideDownRect.origin.x / gridView.font.cellWidth),
            row: Int(upsideDownRect.origin.y / gridView.font.cellHeight)
          ),
          size: .init(
            columnsCount: Int(upsideDownRect.size.width / gridView.font.cellWidth),
            rowsCount: Int(upsideDownRect.size.height / gridView.font.cellHeight)
          )
        )
        let columnsRange = integerFrame.origin.column ..< integerFrame.origin.column + integerFrame.size.columnsCount

        for rowOffset in 0 ..< integerFrame.size.rowsCount {
          let row = integerFrame.origin.row + rowOffset

          guard row >= 0, row < grid.cells.size.rowsCount else {
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

            cgContext.setShouldAntialias(false)
            cgContext.setFillColor(backgroundColor.appKit.cgColor)
            cgContext.fill([upsideDownPartFrame])

            let isBold = highlight?.isBold ?? false
            let isItalic = highlight?.isItalic ?? false

            let font: NSFont
            if isBold, isItalic {
              font = gridView.font.appKit.boldItalic

            } else if isBold {
              font = gridView.font.appKit.bold

            } else if isItalic {
              font = gridView.font.appKit.italic

            } else {
              font = gridView.font.appKit.regular
            }

            let drawRun = drawRunCache.drawRun(for: part.text, font: font) {
              let attributedString = NSAttributedString(
                string: part.text,
                attributes: [.font: font]
              )

              let typesetter = CTTypesetterCreateWithAttributedString(attributedString)
              let line = CTTypesetterCreateLine(typesetter, .init(location: 0, length: 0))
              let runs = CTLineGetGlyphRuns(line) as! [CTRun]

              var glyphRuns = [GlyphRun]()

              for run in runs {
                let glyphCount = CTRunGetGlyphCount(run)

                let glyphPositions = [CGPoint](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
                  CTRunGetPositions(run, .init(location: 0, length: 0), buffer.baseAddress!)
                  initializedCount = glyphCount
                }

                let glyphs = [CGGlyph](unsafeUninitializedCapacity: glyphCount) { buffer, initializedCount in
                  CTRunGetGlyphs(run, .init(location: 0, length: 0), buffer.baseAddress!)
                  initializedCount = glyphCount
                }

                glyphRuns.append(
                  .init(
                    font: font,
                    textMatrix: CTRunGetTextMatrix(run),
                    positions: glyphPositions,
                    glyphs: glyphs
                  )
                )
              }

              return DrawRun(text: part.text, size: partFrame.size, glyphRuns: glyphRuns)
            }

            cgContext.setShouldAntialias(true)
            cgContext.setFillColor(foregroundColor.appKit.cgColor)
            drawRun.draw(at: upsideDownPartFrame.origin, with: cgContext)

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

              cgContext.saveGState()

              cgContext.setShouldAntialias(false)
              cgContext.setFillColor(.white)
              cgContext.fill([cursorUpsideDownFrame])

              cgContext.clip(to: [cursorUpsideDownFrame])

              cgContext.setShouldAntialias(true)
              cgContext.setFillColor(.black)
              drawRun.draw(at: upsideDownPartFrame.origin, with: cgContext)

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
      guard let data else {
        return
      }

      let yThreshold = data.gridView.font.cellHeight * 1.5
      let xThreshold = data.gridView.font.cellWidth * 3

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

    var data: (drawRunCache: DrawRunCache, gridView: GridView)? {
      didSet {
        cancellable?.cancel()
        cancellable = nil

        state = nil

        guard let data else {
          return
        }

        let id = data.gridView.gridID

        let viewStore = ViewStore(
          data.gridView.store,
          observe: { $0 },
          removeDuplicates: {
            $0.grids[id: id]?.updateFlag == $1.grids[id: id]?.updateFlag
          }
        )

        cancellable = viewStore.publisher
          .sink { [weak self] state in
            self?.state = state
            self?.render()
          }
      }
    }

    private var state: Instance.State?
    private var cancellable: AnyCancellable?
    private var xScrollingAccumulator: Double = 0
    private var yScrollingAccumulator: Double = 0
    private var isScrollingHorizontal: Bool?

    private func render() {
      guard let data, let state else {
        return
      }

      let grid = state.grids[id: data.gridView.gridID]!

      if grid.updates.isEmpty {
        setNeedsDisplay(bounds)

      } else {
        let dirtyRects = grid.updates
          .map { rectangle in
            let rect = rectangle * data.gridView.font.cellSize
            let upsideDownRect = CGRect(
              origin: .init(
                x: rect.origin.x,
                y: bounds.height - rect.origin.y - rect.size.height
              ),
              size: rect.size
            )
            return upsideDownRect
          }

        for dirtyRect in dirtyRects {
          setNeedsDisplay(dirtyRect)
        }
      }
    }

    private func report(_ nsEvent: NSEvent, of content: MouseEvent.Content) {
      guard let data else {
        return
      }

      let location = convert(nsEvent.locationInWindow, from: nil)
      let upsideDownLocation = CGPoint(
        x: location.x,
        y: bounds.height - location.y
      )
      let point = IntegerPoint(
        column: Int(upsideDownLocation.x / data.gridView.font.cellWidth),
        row: Int(upsideDownLocation.y / data.gridView.font.cellHeight)
      )
      let event = MouseEvent(content: content, gridID: data.gridView.gridID, point: point)
      data.gridView.mouseEventHandler(event)
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

  public var body: some View {
    HostingView(gridView: self)
  }
}
