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
  public init(store: Store<Model, Action>) {
    self.store = store
  }

  public var store: Store<Model, Action>

  public struct Model {
    public init(
      grid: Grid,
      grids: IdentifiedArrayOf<Grid>,
      cursor: Cursor? = nil,
      modeInfo: ModeInfo,
      mode: Mode,
      reportMouseEvent: @escaping (MouseEvent) -> Void
    ) {
      self.grid = grid
      self.grids = grids
      self.cursor = cursor
      self.modeInfo = modeInfo
      self.mode = mode
      self.reportMouseEvent = reportMouseEvent
    }

    public var grid: Grid
    public var grids: IdentifiedArrayOf<Grid>
    public var cursor: Cursor?
    public var modeInfo: ModeInfo
    public var mode: Mode
    public var reportMouseEvent: (MouseEvent) -> Void
  }

  public enum Action: Equatable {}

  public var body: some View {
    HostingView(store: store)
  }

  @MainActor
  public struct HostingView: NSViewRepresentable {
    public var store: Store<Model, Action>

    public func makeNSView(context: Context) -> NSView {
      let view = NSView()
      updateNSView(view, context: context)
      return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
      nsView.drawRunCache = context.environment.drawRunCache
      nsView.nimsAppearance = context.environment.nimsAppearance
      nsView.suspendingClock = context.environment.suspendingClock
      nsView.viewStore = .init(
        store,
        observe: { $0 },
        removeDuplicates: { $0.grid.updateFlag == $1.grid.updateFlag }
      )
    }
  }

  @MainActor
  public class NSView: AppKit.NSView {
    var drawRunCache: DrawRunCache?
    var nimsAppearance: NimsAppearance?
    var suspendingClock: (any Clock<Duration>)?

    var viewStore: ViewStore<GridView.Model, GridView.Action>? {
      didSet {
        viewStoreCancellable?.cancel()
        viewStoreCancellable = nil

        guard let viewStore else {
          return
        }

        viewStoreCancellable = viewStore.publisher
          .sink { [weak self] model in
            self?.model = model
            self?.render()
          }
      }
    }

    private var viewStoreCancellable: AnyCancellable?
    private var model: GridView.Model?
    private var cursorBlinkingTask: Task<Void, Never>?
    private var cursorBlinkingPhase = true
    private var xScrollingAccumulator: Double = 0
    private var yScrollingAccumulator: Double = 0
    private var isScrollingHorizontal: Bool?

    private func render() {
      cursorBlinkingTask?.cancel()
      cursorBlinkingTask = nil
      cursorBlinkingPhase = true
      renderCursorBlinkingPhase()

      guard let suspendingClock, let model else {
        return
      }

      if let cursor = model.cursor, cursor.gridID == model.grid.id {
        let cursorStyle = model.modeInfo.cursorStyles[model.mode.cursorStyleIndex]

        if
          let blinkWait = cursorStyle.blinkWait, blinkWait > 0,
          let blinkOff = cursorStyle.blinkOff, blinkOff > 0,
          let blinkOn = cursorStyle.blinkOn, blinkOn > 0
        {
          cursorBlinkingTask = Task {
            do {
              try await suspendingClock.sleep(for: .milliseconds(blinkWait))
              guard !Task.isCancelled else {
                return
              }
              self.cursorBlinkingPhase = false
              self.renderCursorBlinkingPhase()

              while true {
                try await suspendingClock.sleep(for: .milliseconds(blinkOff))
                guard !Task.isCancelled else {
                  return
                }
                self.cursorBlinkingPhase = true
                self.renderCursorBlinkingPhase()

                try await suspendingClock.sleep(for: .milliseconds(blinkOn))
                guard !Task.isCancelled else {
                  return
                }
                self.cursorBlinkingPhase = false
                self.renderCursorBlinkingPhase()
              }
            } catch {
              let isCancellation = error is CancellationError

              if !isCancellation {
                assertionFailure("\(error)")
              }
            }
          }
        }
      }

      let grid = model.grid
      render(gridUpdates: grid.updates)
    }

    private func renderCursorBlinkingPhase() {
      guard
        let model,
        let cursor = model.cursor,
        cursor.gridID == model.grid.id
      else {
        return
      }

      let cursorFrame = IntegerRectangle(
        origin: cursor.position,
        size: .init(columnsCount: 1, rowsCount: 1)
      )
      render(gridUpdates: [cursorFrame])
    }

    private func render(gridUpdates: [IntegerRectangle]) {
      guard let nimsAppearance else {
        return
      }

      if gridUpdates.isEmpty {
        setNeedsDisplay(bounds)

      } else {
        let dirtyRects = gridUpdates
          .map { rectangle in
            let rect = rectangle * nimsAppearance.cellSize
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

    override public func draw(_: NSRect) {
      guard let graphicsContext = NSGraphicsContext.current, let drawRunCache, let nimsAppearance, let model else {
        return
      }

      let cellSize = nimsAppearance.cellSize
      let cgContext = graphicsContext.cgContext
      let grid = model.grid

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
            column: Int(upsideDownRect.origin.x / nimsAppearance.cellWidth),
            row: Int(upsideDownRect.origin.y / nimsAppearance.cellHeight)
          ),
          size: .init(
            columnsCount: Int(ceil(upsideDownRect.size.width / nimsAppearance.cellWidth)),
            rowsCount: Int(ceil(upsideDownRect.size.height / nimsAppearance.cellHeight))
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
            let highlight = nimsAppearance.highlights[id: part.highlightID]
            let backgroundColor = highlight?.backgroundColor ?? nimsAppearance.defaultBackgroundColor
            let foregroundColor = highlight?.foregroundColor ?? nimsAppearance.defaultForegroundColor

            let partIntegerFrame = IntegerRectangle(
              origin: .init(column: part.indices.lowerBound, row: row),
              size: .init(columnsCount: part.indices.count, rowsCount: 1)
            )
            let partFrame = partIntegerFrame * nimsAppearance.cellSize
            let upsideDownPartFrame = CGRect(
              origin: .init(
                x: partFrame.origin.x,
                y: bounds.height - partFrame.origin.y - nimsAppearance.cellHeight
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
              font = nimsAppearance.font.appKit.boldItalic

            } else if isBold {
              font = nimsAppearance.font.appKit.bold

            } else if isItalic {
              font = nimsAppearance.font.appKit.italic

            } else {
              font = nimsAppearance.font.appKit.regular
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
              self.cursorBlinkingPhase,
              let cursor = model.cursor,
              cursor.gridID == model.grid.id,
              cursor.position.row == row,
              cursor.position.column >= part.indices.lowerBound,
              cursor.position.column < part.indices.upperBound
            {
              let cursorStyle = model.modeInfo
                .cursorStyles[model.mode.cursorStyleIndex]

              if let cursorShape = cursorStyle.cursorShape {
                let cursorFrame: CGRect
                switch cursorShape {
                case .block:
                  let integerFrame = IntegerRectangle(
                    origin: cursor.position,
                    size: .init(columnsCount: 1, rowsCount: 1)
                  )
                  cursorFrame = integerFrame * cellSize

                case .horizontal:
                  let height = cellSize.height / 100.0 * Double(cursorStyle.cellPercentage ?? 25)

                  cursorFrame = CGRect(
                    x: Double(cursor.position.column) * cellSize.width,
                    y: Double(cursor.position.row) * cellSize.height,
                    width: cellSize.width,
                    height: height
                  )

                case .vertical:
                  let width = cellSize.width / 100.0 * Double(cursorStyle.cellPercentage ?? 25)

                  cursorFrame = CGRect(
                    origin: cursor.position * cellSize,
                    size: .init(width: width, height: cellSize.height)
                  )
                }

                let cursorUpsideDownFrame = CGRect(
                  origin: .init(
                    x: cursorFrame.origin.x,
                    y: bounds.height - cursorFrame.origin.y - cellSize.height
                  ),
                  size: cursorFrame.size
                )

                let cursorBackgroundColor: NimsColor
                let cursorForegroundColor: NimsColor
                if let highlightID = cursorStyle.attrID {
                  if highlightID == .zero {
                    cursorBackgroundColor = foregroundColor
                    cursorForegroundColor = backgroundColor

                  } else {
                    let highlight = nimsAppearance.highlights[id: highlightID]
                    cursorBackgroundColor = highlight?.backgroundColor ?? foregroundColor
                    cursorForegroundColor = highlight?.foregroundColor ?? backgroundColor
                  }

                } else {
                  cursorBackgroundColor = foregroundColor
                  cursorForegroundColor = backgroundColor
                }

                cgContext.saveGState()

                cgContext.setShouldAntialias(false)
                cgContext.setFillColor(cursorBackgroundColor.appKit.cgColor)
                cgContext.fill([cursorUpsideDownFrame])

                if cursorShape == .block {
                  cgContext.clip(to: [cursorUpsideDownFrame])

                  cgContext.setShouldAntialias(true)
                  cgContext.setFillColor(cursorForegroundColor.appKit.cgColor)
                  drawRun.draw(at: upsideDownPartFrame.origin, with: cgContext)
                }

                cgContext.restoreGState()
              }
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
      guard let nimsAppearance else {
        return
      }

      let yThreshold = nimsAppearance.cellHeight * 1.5
      let xThreshold = nimsAppearance.cellWidth * 2

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

        } else if abs(xScrollingAccumulator) >= xThreshold * 1.5 {
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

    private func report(_ nsEvent: NSEvent, of content: MouseEvent.Content) {
      guard let nimsAppearance, let model else {
        return
      }

      let location = convert(nsEvent.locationInWindow, from: nil)
      let upsideDownLocation = CGPoint(
        x: location.x,
        y: bounds.height - location.y
      )
      let point = IntegerPoint(
        column: Int(upsideDownLocation.x / nimsAppearance.font.cellWidth),
        row: Int(upsideDownLocation.y / nimsAppearance.font.cellHeight)
      )
      model.reportMouseEvent(
        .init(content: content, gridID: model.grid.id, point: point)
      )
    }
  }
}
