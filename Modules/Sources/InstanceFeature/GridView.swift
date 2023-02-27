// SPDX-License-Identifier: MIT

import AppKit
import CasePaths
import Collections
import Combine
import ComposableArchitecture
import Dependencies
import IdentifiedCollections
import Library
import Neovim
import Overture
import SwiftUI
import Tagged

public struct GridView: View {
  public init(store: Store<Model, Action>, reportMouseEvent: @escaping (MouseEvent) -> Void) {
    self.store = store
    self.reportMouseEvent = reportMouseEvent
  }

  public var store: Store<Model, Action>
  public var reportMouseEvent: (MouseEvent) -> Void

  public struct Model {
    public init(
      gridID: Grid.ID,
      grids: IntKeyedDictionary<Grid>,
      cursor: Cursor? = nil,
      modeInfo: ModeInfo?,
      mode: Mode?,
      cursorBlinkingPhase: Bool
    ) {
      self.gridID = gridID
      self.grids = grids
      self.cursor = cursor
      self.modeInfo = modeInfo
      self.mode = mode
      self.cursorBlinkingPhase = cursorBlinkingPhase
    }

    public var gridID: Grid.ID
    public var grids: IntKeyedDictionary<Grid>
    public var cursor: Cursor?
    public var modeInfo: ModeInfo?
    public var mode: Mode?
    public var cursorBlinkingPhase: Bool

    public var grid: Grid {
      grids[gridID]!
    }
  }

  public enum Action: Sendable {}

  public var body: some View {
    HostingView(
      store: store,
      reportMouseEvent: reportMouseEvent
    )
  }

  public struct HostingView: NSViewRepresentable {
    public init(store: Store<GridView.Model, GridView.Action>, reportMouseEvent: @escaping (MouseEvent) -> Void) {
      self.store = store
      self.reportMouseEvent = reportMouseEvent
    }

    public var store: Store<Model, Action>
    public var reportMouseEvent: (MouseEvent) -> Void

    public func makeNSView(context: Context) -> NSView {
      let view = NSView()
      view.wantsLayer = true
      view.canDrawConcurrently = true
      updateNSView(view, context: context)
      return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
      nsView.nimsAppearance = context.environment.nimsAppearance
      nsView.reportMouseEvent = reportMouseEvent
      nsView.viewStore = ViewStore(
        store,
        observe: { $0 },
        removeDuplicates: {
          $0.grid.updateFlag == $1.grid.updateFlag
        }
      )
    }

    @Dependency(\.drawRunsProvider)
    private var drawRunsProvider: DrawRunsProvider
  }

  public class NSView: AppKit.NSView {
    var nimsAppearance: NimsAppearance?
    var reportMouseEvent: ((MouseEvent) -> Void)?
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

    private let drawRunsProvider = DrawRunsProvider()
    private var viewStoreCancellable: AnyCancellable?
    private var model: GridView.Model?

    private func render() {
      guard let nimsAppearance, let model else {
        return
      }

      if model.grid.updates.isEmpty {
        setNeedsDisplay(bounds)

      } else {
        let dirtyRects = model.grid.updates
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
      guard let graphicsContext = NSGraphicsContext.current, let nimsAppearance, let model else {
        return
      }

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
            let backgroundColor = nimsAppearance.backgroundColor(for: part.highlightID)

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

            backgroundColor.appKit.setFill()
            cgContext.fill([upsideDownPartFrame])

            let drawRun = drawRunsProvider
              .drawRun(
                with: .init(
                  integerSize: .init(
                    columnsCount: part.indices.count,
                    rowsCount: 1
                  ),
                  text: part.text,
                  font: nimsAppearance.font,
                  isItalic: nimsAppearance.isItalic(for: part.highlightID),
                  isBold: nimsAppearance.isBold(for: part.highlightID),
                  decorations: nimsAppearance.decorations(for: part.highlightID)
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
              let modeInfo = model.modeInfo,
              let mode = model.mode,
              model.cursorBlinkingPhase,
              let cursor = model.cursor,
              cursor.gridID == model.gridID,
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
                  cursorFrame = integerFrame * nimsAppearance.cellSize

                case .horizontal:
                  let height = nimsAppearance.cellSize.height / 100.0 * Double(cursorStyle.cellPercentage ?? 25)

                  cursorFrame = CGRect(
                    x: Double(cursor.position.column) * nimsAppearance.cellSize.width,
                    y: Double(cursor.position.row) * nimsAppearance.cellSize.height,
                    width: nimsAppearance.cellSize.width,
                    height: height
                  )

                case .vertical:
                  let width = nimsAppearance.cellSize.width / 100.0 * Double(cursorStyle.cellPercentage ?? 25)

                  cursorFrame = CGRect(
                    origin: cursor.position * nimsAppearance.cellSize,
                    size: .init(width: width, height: nimsAppearance.cellSize.height)
                  )
                }

                let cursorUpsideDownFrame = CGRect(
                  origin: .init(
                    x: cursorFrame.origin.x,
                    y: bounds.height - cursorFrame.origin.y - nimsAppearance.cellSize.height
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
          let foregroundColor = nimsAppearance.foregroundColor(for: highlightID)
          let specialColor = nimsAppearance.specialColor(for: highlightID)

          drawRun.draw(
            at: origin,
            to: graphicsContext,
            foregroundColor: foregroundColor,
            specialColor: specialColor
          )
        }

        if let cursorDrawRun {
          graphicsContext.saveGraphicsState()

          let cursorForegroundColor: NimsColor
          let cursorBackgroundColor: NimsColor

          if cursorDrawRun.highlightID.isDefault {
            cursorForegroundColor = nimsAppearance.backgroundColor(for: cursorDrawRun.parentHighlightID)
            cursorBackgroundColor = nimsAppearance.foregroundColor(for: cursorDrawRun.parentHighlightID)

          } else {
            cursorForegroundColor = nimsAppearance.foregroundColor(for: cursorDrawRun.highlightID)
            cursorBackgroundColor = nimsAppearance.backgroundColor(for: cursorDrawRun.highlightID)
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
      guard let nimsAppearance else {
        return
      }
      let cellSize = nimsAppearance.cellSize

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
      guard let nimsAppearance, let model else {
        return
      }

      let location = convert(nsEvent.locationInWindow, from: nil)
      let upsideDownLocation = CGPoint(
        x: location.x,
        y: bounds.height - location.y
      )
      let point = IntegerPoint(
        column: Int(upsideDownLocation.x / nimsAppearance.cellWidth),
        row: Int(upsideDownLocation.y / nimsAppearance.cellHeight)
      )
      reportMouseEvent?(.init(content: content, gridID: model.gridID, point: point))
    }
  }
}
