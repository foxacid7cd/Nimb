// SPDX-License-Identifier: MIT

import CasePaths
import Collections
import ComposableArchitecture
import Library
import Neovim
import Overture
import SwiftUI

public extension Instance {
  @MainActor
  struct View: SwiftUI.View {
    public init(
      font: Instance.State.Font,
      defaultForegroundColor: Instance.State.Color,
      defaultBackgroundColor: Instance.State.Color,
      defaultSpecialColor: Instance.State.Color,
      outerGridSize: IntegerSize,
      highlights: IdentifiedArrayOf<State.Highlight>,
      store: StoreOf<Instance>
    ) {
      self.font = font
      self.defaultForegroundColor = defaultForegroundColor
      self.defaultBackgroundColor = defaultBackgroundColor
      self.defaultSpecialColor = defaultSpecialColor
      self.outerGridSize = outerGridSize
      self.highlights = highlights
      self.store = store
    }

    public struct WindowsViewModel: Equatable {
      public init(
        grids: IdentifiedArrayOf<State.Grid>,
        windows: IdentifiedArrayOf<Instance.State.Window>,
        floatingWindows: IdentifiedArrayOf<State.FloatingWindow>,
        cursor: State.Cursor?
      ) {
        self.grids = grids
        self.windows = windows
        self.floatingWindows = floatingWindows
        self.cursor = cursor
      }

      public init(state: State) {
        self.init(
          grids: state.grids,
          windows: state.windows,
          floatingWindows: state.floatingWindows,
          cursor: state.cursor
        )
      }

      public var grids: IdentifiedArrayOf<State.Grid>
      public var windows: IdentifiedArrayOf<State.Window>
      public var floatingWindows: IdentifiedArrayOf<State.FloatingWindow>
      public var cursor: State.Cursor?
    }

    public var font: State.Font
    public var defaultForegroundColor: Instance.State.Color
    public var defaultBackgroundColor: Instance.State.Color
    public var defaultSpecialColor: Instance.State.Color
    public var outerGridSize: IntegerSize
    public var highlights: IdentifiedArrayOf<State.Highlight>
    public var store: StoreOf<Instance>

    public var body: some SwiftUI.View {
      WithViewStore(store, observe: WindowsViewModel.init(state:)) { windowsViewModel in
        let outerGridSize = outerGridSize * font.cellSize
        let outerGridFrame = CGRect(origin: .init(), size: outerGridSize)

        ZStack(alignment: .topLeading) {
          Grid(
            font: font,
            highlights: highlights,
            defaultForegroundColor: defaultForegroundColor,
            defaultBackgroundColor: defaultBackgroundColor,
            defaultSpecialColor: defaultSpecialColor,
            grid: windowsViewModel.grids[id: .outer]!,
            cursor: windowsViewModel.cursor
          )
          .frame(width: outerGridSize.width, height: outerGridSize.height)
          .zIndex(0)

          ForEach(windowsViewModel.windows) { window in
            let grid = windowsViewModel.grids[id: window.gridID]!

            let frame = window.frame * font.cellSize
            let clippedFrame = frame.intersection(outerGridFrame)

            Grid(
              font: font,
              highlights: highlights,
              defaultForegroundColor: defaultForegroundColor,
              defaultBackgroundColor: defaultBackgroundColor,
              defaultSpecialColor: defaultSpecialColor,
              grid: grid,
              cursor: windowsViewModel.cursor
            )
            .frame(width: clippedFrame.width, height: clippedFrame.height)
            .offset(x: clippedFrame.minX, y: clippedFrame.minY)
            .zIndex(Double(window.zIndex) / 1000 + 1000)
            .opacity(window.isHidden ? 0 : 1)
          }

          ForEach(windowsViewModel.floatingWindows) { floatingWindow in
            let grid = windowsViewModel.grids[id: floatingWindow.gridID]!

            let frame = calculateFrame(
              for: floatingWindow,
              grid: windowsViewModel.grids[id: floatingWindow.gridID]!,
              grids: windowsViewModel.grids,
              windows: windowsViewModel.windows,
              floatingWindows: windowsViewModel.floatingWindows,
              cellSize: font.cellSize
            )
            let clippedFrame = frame.intersection(outerGridFrame)

            Grid(
              font: font,
              highlights: highlights,
              defaultForegroundColor: defaultForegroundColor,
              defaultBackgroundColor: defaultBackgroundColor,
              defaultSpecialColor: defaultSpecialColor,
              grid: grid,
              cursor: windowsViewModel.cursor
            )
            .frame(width: clippedFrame.width, height: clippedFrame.height)
            .offset(x: clippedFrame.minX, y: clippedFrame.minY)
            .zIndex(Double(floatingWindow.zIndex) / 1000 + 1_000_000)
            .opacity(floatingWindow.isHidden ? 0 : 1)
          }
        }
        .frame(width: outerGridSize.width, height: outerGridSize.height)
      }
    }

    @MainActor
    struct Grid: SwiftUI.View {
      public init(
        font: Instance.State.Font,
        highlights: IdentifiedArrayOf<Instance.State.Highlight>,
        defaultForegroundColor: Instance.State.Color,
        defaultBackgroundColor: Instance.State.Color,
        defaultSpecialColor: Instance.State.Color,
        grid: Instance.State.Grid,
        cursor: Instance.State.Cursor? = nil
      ) {
        self.font = font
        self.highlights = highlights
        self.defaultForegroundColor = defaultForegroundColor
        self.defaultBackgroundColor = defaultBackgroundColor
        self.defaultSpecialColor = defaultSpecialColor
        self.grid = grid
        self.cursor = cursor
      }

      public var font: State.Font
      public var highlights: IdentifiedArrayOf<State.Highlight>
      public var defaultForegroundColor: Instance.State.Color
      public var defaultBackgroundColor: Instance.State.Color
      public var defaultSpecialColor: Instance.State.Color
      public var grid: State.Grid
      public var cursor: State.Cursor?

      public var body: some SwiftUI.View {
        Canvas(opaque: true, colorMode: .extendedLinear) { graphicsContext, size in
          graphicsContext.fill(
            Path(CGRect(origin: .init(), size: size)),
            with: .color(defaultBackgroundColor.swiftUI),
            style: .init(antialiased: false)
          )

          var backgroundRuns = [(frame: CGRect, color: State.Color)]()
          var foregroundRuns = [(origin: CGPoint, text: Text)]()

          for (row, rowLayout) in zip(0..<grid.rowLayouts.count, grid.rowLayouts) {
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

          if let cursor, cursor.gridID == grid.id {
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
      }
    }

    private func calculateFrame(
      for floatingWindow: State.FloatingWindow,
      grid: State.Grid,
      grids: IdentifiedArrayOf<State.Grid>,
      windows: IdentifiedArrayOf<State.Window>,
      floatingWindows: IdentifiedArrayOf<State.FloatingWindow>,
      cellSize: CGSize
    )
      -> CGRect
    {
      let anchorGrid = grids[id: floatingWindow.anchorGridID]!

      let anchorGridOrigin: CGPoint
      if let windowID = anchorGrid.windowID {
        if let window = windows[id: windowID] {
          anchorGridOrigin = window.frame.origin * cellSize

        } else {
          let floatingWindow = floatingWindows[id: windowID]!

          anchorGridOrigin = calculateFrame(
            for: floatingWindow,
            grid: grids[id: floatingWindow.gridID]!,
            grids: grids,
            windows: windows,
            floatingWindows: floatingWindows,
            cellSize: cellSize
          )
          .origin
        }

      } else {
        anchorGridOrigin = .init()
      }

      var frame = CGRect(
        origin: .init(
          x: anchorGridOrigin.x + (floatingWindow.anchorColumn * cellSize.width),
          y: anchorGridOrigin.y + (floatingWindow.anchorRow * cellSize.height)
        ),
        size: grid.cells.size * cellSize
      )

      switch floatingWindow.anchor {
      case .northWest:
        break

      case .northEast:
        frame.origin.x -= frame.size.width

      case .southWest:
        frame.origin.y -= frame.size.height

      case .southEast:
        frame.origin.x -= frame.size.width
        frame.origin.y -= frame.size.height
      }

      return frame
    }
  }
}
