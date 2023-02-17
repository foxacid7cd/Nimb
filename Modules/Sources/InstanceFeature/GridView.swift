// SPDX-License-Identifier: MIT

import AppKit
import CasePaths
import Collections
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

  public var gridID: Grid.ID
  public var font: Font
  public var highlights: IdentifiedArrayOf<Highlight>
  public var defaultForegroundColor: Color
  public var defaultBackgroundColor: Color
  public var defaultSpecialColor: Color
  public var store: StoreOf<Instance>
  public var mouseEventHandler: (MouseEvent) -> Void

  public var body: some SwiftUI.View {
    WithViewStore(
      store,
      observe: { $0 },
      removeDuplicates: {
        $0.gridUpdateFlags[gridID] == $1.gridUpdateFlags[gridID]
      }
    ) { state in
      let grid = state.grids[id: gridID]!

      let overlay = Overlay(font: font) { content, point in
        let event = MouseEvent(
          content: content,
          gridID: gridID,
          point: point
        )
        mouseEventHandler(event)
      }

      Canvas(opaque: true, colorMode: .extendedLinear, rendersAsynchronously: true) { graphicsContext, size in
        graphicsContext.fill(
          Path(CGRect(origin: .init(), size: size)),
          with: .color(defaultBackgroundColor.swiftUI),
          style: .init(antialiased: false)
        )

        var backgroundRuns = [(frame: CGRect, color: Color)]()
        var foregroundRuns = [(origin: CGPoint, text: Text)]()

        for (row, rowLayout) in zip(0 ..< grid.rowLayouts.count, grid.rowLayouts) {
          let rowFrame = CGRect(
            origin: .init(x: 0, y: Double(row) * font.cellHeight),
            size: .init(width: size.width, height: font.cellHeight)
          )

          for rowPart in rowLayout.parts {
            let frame = CGRect(
              origin: .init(
                x: Double(rowPart.indices.lowerBound) * font.cellWidth,
                y: rowFrame.origin.y
              ),
              size: .init(
                width: Double(rowPart.indices.count) * font.cellWidth,
                height: rowFrame.size.height
              )
            )

            let highlight = highlights[id: rowPart.highlightID]

            let backgroundColor = highlight?.backgroundColor ?? defaultBackgroundColor
            backgroundRuns.append((frame, backgroundColor))

            let foregroundColor = highlight?.foregroundColor ?? defaultForegroundColor

            let text = Text(rowPart.text)
              .font(.init(font.appKit))
              .foregroundColor(foregroundColor.swiftUI)
              .bold(highlight?.isBold == true)
              .italic(highlight?.isItalic == true)

            foregroundRuns.append((frame.origin, text))
          }
        }

        graphicsContext.drawLayer { backgroundGraphicsContext in
          for backgroundRun in backgroundRuns {
            backgroundGraphicsContext.fill(
              Path(backgroundRun.frame),
              with: .color(backgroundRun.color.swiftUI),
              style: .init(antialiased: false)
            )
          }
        }

        graphicsContext.drawLayer { foregroundGraphicsContext in
          for foregroundRun in foregroundRuns {
            foregroundGraphicsContext.draw(
              foregroundRun.text,
              at: foregroundRun.origin,
              anchor: .zero
            )
          }
        }

        if let cursor = state.cursor, cursor.gridID == gridID {
          graphicsContext.drawLayer { cursorGraphicsContext in
            let rowLayout = grid.rowLayouts[cursor.position.row]
            let cursorIndices = rowLayout.cellIndices[cursor.position.column]

            let integerFrame = IntegerRectangle(
              origin: .init(column: cursorIndices.startIndex, row: cursor.position.row),
              size: .init(columnsCount: cursorIndices.count, rowsCount: 1)
            )
            let frame = integerFrame * font.cellSize

            cursorGraphicsContext.fill(
              Path(frame),
              with: .color(.white)
            )

            let cell = grid.cells[cursor.position]

            let text = Text(cell.text)
              .font(.init(font.appKit))
              .foregroundColor(.black)

            cursorGraphicsContext.draw(
              text,
              at: .init(x: frame.midX, y: frame.midY)
            )
          }
        }
      }
      .overlay(overlay)
    }
  }

  private struct Overlay: NSViewRepresentable {
    class NSView: AppKit.NSView {
      var cellSize: CGSize?
      var handleMouseEvent: ((MouseEvent.Content, IntegerPoint) -> Void)?

      override func mouseDown(with event: NSEvent) {
        report(event, of: .mouse(button: .left, action: .press))
      }

      override func mouseDragged(with event: NSEvent) {
        report(event, of: .mouse(button: .left, action: .drag))
      }

      override func mouseUp(with event: NSEvent) {
        report(event, of: .mouse(button: .left, action: .release))
      }

      override func rightMouseDown(with event: NSEvent) {
        report(event, of: .mouse(button: .right, action: .press))
      }

      override func rightMouseDragged(with event: NSEvent) {
        report(event, of: .mouse(button: .right, action: .drag))
      }

      override func rightMouseUp(with event: NSEvent) {
        report(event, of: .mouse(button: .right, action: .release))
      }

      override func otherMouseDown(with event: NSEvent) {
        report(event, of: .mouse(button: .middle, action: .press))
      }

      override func otherMouseDragged(with event: NSEvent) {
        report(event, of: .mouse(button: .middle, action: .drag))
      }

      override func otherMouseUp(with event: NSEvent) {
        report(event, of: .mouse(button: .middle, action: .release))
      }

      override func scrollWheel(with event: NSEvent) {
        guard let cellSize else {
          return
        }

        let yThreshold = cellSize.height
        let xThreshold = cellSize.width * 2

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

      private var xScrollingAccumulator: Double = 0
      private var yScrollingAccumulator: Double = 0
      private var isScrollingHorizontal: Bool?

      private func report(_ nsEvent: NSEvent, of content: MouseEvent.Content) {
        guard let cellSize, let handleMouseEvent else {
          return
        }

        let location = convert(nsEvent.locationInWindow, from: nil)
        let upsideDownLocation = CGPoint(
          x: location.x,
          y: bounds.height - location.y
        )
        let point = IntegerPoint(
          column: Int(upsideDownLocation.x / cellSize.width),
          row: Int(upsideDownLocation.y / cellSize.height)
        )
        handleMouseEvent(content, point)
      }
    }

    var font: Font
    var handleMouseEvent: (MouseEvent.Content, IntegerPoint) -> Void

    func makeNSView(context: Context) -> NSView {
      let view = NSView()
      view.cellSize = font.cellSize
      view.handleMouseEvent = handleMouseEvent
      return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
      nsView.cellSize = font.cellSize
      nsView.handleMouseEvent = handleMouseEvent
    }
  }
}
