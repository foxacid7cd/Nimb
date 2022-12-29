// SPDX-License-Identifier: MIT

import CasePaths
import ComposableArchitecture
import Library
import Neovim
import Overture
import SwiftUI

@MainActor
public struct SnapshotView: View {
  public init(store: Store<State.Snapshot, Action>) {
    self.store = store
  }

  public var store: Store<State.Snapshot, Action>

  public var body: some View {
    WithViewStore(
      store,
      observe: { $0 }
    ) { state in
      if
        let appearance = state.appearance,
        let outerGrid = state.outerGrid
      {
        let integerFrame = IntegerRectangle(size: outerGrid.cells.size)
        let frame = integerFrame * appearance.cellSize

        ZStack(alignment: .topLeading) {
          gridView(
            for: outerGrid,
            appearance: appearance,
            size: outerGrid.cells.size,
            cursor: state.cursor
          )
          .frame(
            width: frame.size.width,
            height: frame.size.height
          )

          ForEach(state.windows) { window in
            let grid = state.grids[id: window.gridID]!
            let integerSize = IntegerSize(
              columnsCount: min(window.frame.size.columnsCount, grid.cells.columnsCount),
              rowsCount: min(window.frame.size.rowsCount, grid.cells.rowsCount)
            )
            let size = integerSize * appearance.cellSize
            let origin = window.frame.origin * appearance.cellSize

            if !window.isHidden {
              gridView(
                for: grid,
                appearance: appearance,
                size: integerSize,
                cursor: state.cursor
              )
              .frame(
                width: size.width,
                height: size.height
              )
              .offset(
                x: origin.x,
                y: origin.y
              )
              .zIndex(Double(window.zIndex) / 1000)
            }
          }

          ForEach(state.floatingWindows) { floatingWindow in
            if !floatingWindow.isHidden {
              let grid = state.grids[id: floatingWindow.gridID]!

              let frame = self.frame(
                for: floatingWindow,
                grid: grid,
                appearance: appearance,
                grids: state.grids,
                windows: state.windows,
                floatingWindows: state.floatingWindows
              )

              gridView(
                for: grid,
                appearance: appearance,
                size: grid.cells.size,
                cursor: state.cursor
              )
              .frame(
                width: frame.size.width,
                height: frame.size.height
              )
              .offset(
                x: frame.origin.x,
                y: frame.origin.y
              )
              .zIndex(Double(floatingWindow.zIndex) / 1000 + 1_000_000)
            }
          }
        }
        .frame(
          width: frame.size.width,
          height: frame.size.height
        )
      }
    }
  }

  private func gridView(
    for grid: State.Grid,
    appearance: State.Appearance,
    size: IntegerSize,
    cursor: State.Cursor?
  )
    -> some View
  {
    Canvas(colorMode: .extendedLinear) { graphicsContext, size in
      let rowDrawRuns: [(backgroundRuns: [(frame: CGRect, color: State.Color)], text: Text, point: CGPoint)] =
        grid.rowLayouts
          .enumerated()
          .map { row, rowLayout in
            let rowFrame = CGRect(
              origin: .init(x: 0, y: Double(row) * appearance.font.cellHeight),
              size: .init(width: size.width, height: appearance.font.cellHeight)
            )

            var backgroundRuns = [(frame: CGRect, color: State.Color)]()
            var rowText = Text("")

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
              let color = appearance.backgroundColor(
                for: rowPart.highlightID
              )
              backgroundRuns.append((frame, color))

              let text = Text(rowPart.text)
                .font(.init(appearance.font.appKit))
                .foregroundColor(
                  appearance
                    .foregroundColor(for: rowPart.highlightID)
                    .swiftUI
                )
              rowText = rowText + text
            }

            return (
              backgroundRuns: backgroundRuns,
              text: rowText,
              point: .init(
                x: rowFrame.midX,
                y: rowFrame.midY
              )
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
          foregroundGraphicsContext.draw(
            rowDrawRun.text,
            at: rowDrawRun.point
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
          let frame = integerFrame * appearance.cellSize

          cursorGraphicsContext.fill(
            Path(frame),
            with: .color(.white)
          )

          let cell = grid.cells[cursor.position]

          let text = Text(cell.text)
            .font(.init(appearance.font.appKit))
            .foregroundColor(.black)

          cursorGraphicsContext.draw(text, in: frame)
        }
      }
    }
  }

  private func frame(
    for floatingWindow: State.FloatingWindow,
    grid: State.Grid,
    appearance: State.Appearance,
    grids: IdentifiedArrayOf<State.Grid>,
    windows: IdentifiedArrayOf<State.Window>,
    floatingWindows: IdentifiedArrayOf<State.FloatingWindow>
  )
    -> CGRect
  {
    let anchorGrid = grids[id: floatingWindow.anchorGridID]!

    let anchorGridOrigin: CGPoint
    if let windowID = anchorGrid.windowID {
      if let window = windows[id: windowID] {
        anchorGridOrigin = window.frame.origin * appearance.cellSize

      } else {
        let floatingWindow = floatingWindows[id: windowID]!

        anchorGridOrigin = self.frame(
          for: floatingWindow,
          grid: grids[id: floatingWindow.gridID]!,
          appearance: appearance,
          grids: grids,
          windows: windows,
          floatingWindows: floatingWindows
        )
        .origin
      }

    } else {
      anchorGridOrigin = .init()
    }

    var frame = CGRect(
      origin: .init(
        x: anchorGridOrigin.x + (floatingWindow.anchorColumn * appearance.font.cellWidth),
        y: anchorGridOrigin.y + (floatingWindow.anchorRow * appearance.font.cellHeight)
      ),
      size: grid.cells.size * appearance.cellSize
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
