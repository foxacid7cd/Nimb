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
  struct WindowView: SwiftUI.View {
    public init(reference: References.Window, gridID: State.Grid.ID) {
      self.reference = reference
      self.gridID = gridID
    }

    public var reference: References.Window
    public var gridID: State.Grid.ID

    public var body: some SwiftUI.View {
      Canvas(colorMode: .extendedLinear) { graphicsContext, size in
        graphicsContext.fill(
          Path(CGRect(origin: .init(), size: size)),
          with: .color(.blue)
        )
      }
    }
  }

  @MainActor
  struct View: SwiftUI.View {
    public init(
      font: Instance.State.Font,
      defaultForegroundColor: Instance.State.Color,
      defaultBackgroundColor: Instance.State.Color,
      defaultSpecialColor: Instance.State.Color,
      outerGridSize: IntegerSize,
      store: StoreOf<Instance>
    ) {
      self.font = font
      self.defaultForegroundColor = defaultForegroundColor
      self.defaultBackgroundColor = defaultBackgroundColor
      self.defaultSpecialColor = defaultSpecialColor
      self.outerGridSize = outerGridSize
      self.store = store
    }

    public struct WindowsViewModel: Equatable {
      public init(
        grids: IdentifiedArrayOf<State.Grid>,
        windows: IdentifiedArrayOf<Instance.State.Window>,
        floatingWindows: IdentifiedArrayOf<State.FloatingWindow>
      ) {
        self.grids = grids
        self.windows = windows
        self.floatingWindows = floatingWindows
      }

      public init(state: State) {
        self.init(
          grids: state.grids,
          windows: state.windows,
          floatingWindows: state.floatingWindows
        )
      }

      public var grids: IdentifiedArrayOf<State.Grid>
      public var windows: IdentifiedArrayOf<State.Window>
      public var floatingWindows: IdentifiedArrayOf<State.FloatingWindow>
    }

    public var font: State.Font
    public var defaultForegroundColor: Instance.State.Color
    public var defaultBackgroundColor: Instance.State.Color
    public var defaultSpecialColor: Instance.State.Color
    public var outerGridSize: IntegerSize
    public var store: StoreOf<Instance>

    public var body: some SwiftUI.View {
      WithViewStore(store, observe: WindowsViewModel.init(state:)) { windowsViewModel in
        let size = outerGridSize * font.cellSize

        ZStack(alignment: .topLeading) {
          Canvas(colorMode: .extendedLinear) { graphicsContext, size in
            graphicsContext.fill(
              Path(CGRect(origin: .init(), size: size)),
              with: .color(defaultBackgroundColor.swiftUI)
            )
          }
          .frame(width: size.width, height: size.height)

          ForEach(windowsViewModel.windows) { window in
            let frame = window.frame * font.cellSize

            WindowView(
              reference: window.reference,
              gridID: window.gridID
            )
            .frame(width: frame.width, height: frame.height)
            .offset(x: frame.minX, y: frame.minY)
            .zIndex(Double(window.zIndex) / 1000)
            .opacity(window.isHidden ? 0 : 1)
          }

          ForEach(windowsViewModel.floatingWindows) { floatingWindow in
            let frame = calculateFrame(
              for: floatingWindow,
              grid: windowsViewModel.grids[id: floatingWindow.gridID]!,
              grids: windowsViewModel.grids,
              windows: windowsViewModel.windows,
              floatingWindows: windowsViewModel.floatingWindows,
              cellSize: font.cellSize
            )

            WindowView(
              reference: floatingWindow.reference,
              gridID: floatingWindow.gridID
            )
            .frame(width: frame.width, height: frame.height)
            .offset(x: frame.minX, y: frame.minY)
            .zIndex(Double(floatingWindow.zIndex) / 1000 + 1_000_000)
            .opacity(floatingWindow.isHidden ? 0 : 1)
          }
        }
        .frame(width: size.width, height: size.height)
      }
    }

    private func gridView(
      for grid: State.Grid,
      appearance: State.Appearance,
      size: IntegerSize,
      cursor: State.Cursor?
    )
      -> some SwiftUI.View
    {
      Canvas(colorMode: .extendedLinear) { graphicsContext, size in
        let rowDrawRuns: [(
          backgroundRuns: [(frame: CGRect, color: State.Color)],
          foregroundRuns: [(origin: CGPoint, text: Text)]
        )] =
          grid.rowLayouts
            .enumerated()
            .map { row, rowLayout in
              let rowFrame = CGRect(
                origin: .init(x: 0, y: Double(row) * appearance.font.cellHeight),
                size: .init(width: size.width, height: appearance.font.cellHeight)
              )

              var backgroundRuns = [(frame: CGRect, color: State.Color)]()
              var foregroundRuns = [(origin: CGPoint, text: Text)]()

              for rowPart in rowLayout.parts {
                let frame = CGRect(
                  origin: .init(
                    x: Double(rowPart.indices.lowerBound) * appearance.font.cellWidth,
                    y: rowFrame.origin.y
                  ),
                  size: .init(
                    width: Double(rowPart.indices.count) * appearance.font.cellWidth,
                    height: rowFrame.size.height
                  )
                )

                let backgroundColor = appearance.backgroundColor(
                  for: rowPart.highlightID
                )

                backgroundRuns.append((frame, backgroundColor))

                let textAttributes = appearance.textAttributes(for: rowPart.highlightID)

                let text = Text(rowPart.text)
                  .font(.init(appearance.font.appKit))
                  .foregroundColor(
                    appearance
                      .foregroundColor(for: rowPart.highlightID)
                      .swiftUI
                  )
                  .bold(textAttributes.isBold)
                  .italic(textAttributes.isItalic)

                foregroundRuns.append((frame.origin, text))
              }

              return (
                backgroundRuns: backgroundRuns,
                foregroundRuns: foregroundRuns
              )
            }

        graphicsContext.drawLayer { backgroundGraphicsContext in
          for rowDrawRun in rowDrawRuns {
            for backgroundRun in rowDrawRun.backgroundRuns {
              backgroundGraphicsContext.fill(
                Path(backgroundRun.frame),
                with: .color(backgroundRun.color.swiftUI),
                style: .init(antialiased: false)
              )
            }
          }
        }

        graphicsContext.drawLayer { foregroundGraphicsContext in
          for rowDrawRun in rowDrawRuns {
            for foregroundRun in rowDrawRun.foregroundRuns {
              foregroundGraphicsContext.draw(
                foregroundRun.text,
                at: foregroundRun.origin,
                anchor: .zero
              )
            }
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
            let frame = integerFrame * appearance.cellSize

            cursorGraphicsContext.fill(
              Path(frame),
              with: .color(.white)
            )

            let cell = grid.cells[cursor.position]

            let text = Text(cell.text)
              .font(.init(appearance.font.appKit))
              .foregroundColor(.black)

            cursorGraphicsContext.draw(
              text,
              at: .init(x: frame.midX, y: frame.midY)
            )
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
