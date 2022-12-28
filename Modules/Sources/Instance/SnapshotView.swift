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
        let outerGrid = state.outerGrid {
        let frameWidth = Double(outerGrid.cells.columnsCount) * appearance.font.cellWidth
        let frameHeight = Double(outerGrid.cells.rowsCount) * appearance.font.cellHeight

        ZStack(alignment: .topLeading) {
          gridView(
            for: outerGrid,
            appearance: appearance,
            size: outerGrid.cells.size,
            cursor: state.cursor
          )
          .frame(
            width: frameWidth,
            height: frameHeight
          )

          ForEach(state.windows) { window in
            if !window.isHidden {
              gridView(
                for: state.grids[id: window.gridID]!,
                appearance: appearance,
                size: window.frame.size,
                cursor: state.cursor
              )
              .frame(
                width: Double(window.frame.size.columnsCount) * appearance.font.cellWidth,
                height: Double(window.frame.size.rowsCount) * appearance.font.cellHeight
              )
              .offset(
                x: Double(window.frame.origin.column) * appearance.font.cellWidth,
                y: Double(window.frame.origin.row) * appearance.font.cellHeight
              )
              .zIndex(Double(window.zIndex) / 1000)
            }
          }

          ForEach(state.floatingWindows) { floatingWindow in
            if !floatingWindow.isHidden {
              let grid = state.grids[id: floatingWindow.gridID]!

              gridView(
                for: grid,
                appearance: appearance,
                size: grid.cells.size,
                cursor: state.cursor
              )
              .frame(
                width: Double(grid.cells.size.columnsCount) * appearance.font.cellWidth,
                height: Double(grid.cells.size.rowsCount) * appearance.font.cellHeight
              )
              .offset(
                x: Double(floatingWindow.anchorColumn) * appearance.font.cellWidth,
                y: Double(floatingWindow.anchorRow) * appearance.font.cellHeight
              )
              .zIndex(Double(floatingWindow.zIndex) / 1000 + 1_000_000)
            }
          }
        }
        .frame(
          width: frameWidth,
          height: frameHeight
        )

      } else {
        EmptyView()
      }
    }
  }

  private func gridView(
    for grid: State.Grid,
    appearance: State.Appearance,
    size: IntegerSize,
    cursor: State.Cursor?
  ) -> some View {
    Canvas(rendersAsynchronously: true) { graphicsContext, _ in
      let rowDrawRuns: [(frame: CGRect, backgroundColor: State.Color, text: Text)] = grid.rowHighlightChunks
        .enumerated()
        .flatMap { row, highlightChunks in
          highlightChunks
            .map { highlightChunk in
              let frame = CGRect(
                origin: .init(
                  x: Double(highlightChunk.originColumn) * appearance.font.cellWidth,
                  y: Double(row) * appearance.font.cellHeight
                ),
                size: .init(
                  width: Double(highlightChunk.columnsCount) * appearance.font.cellWidth,
                  height: appearance.font.cellHeight
                )
              )

              let text = Text(highlightChunk.text)
                .font(.init(appearance.font.appKit))
                .foregroundColor(
                  appearance.foregroundColor(for: highlightChunk.highlightID)
                    .swiftUI
                )

              let backgroundColor = appearance.backgroundColor(for: highlightChunk.highlightID)

              return (frame, backgroundColor, text)
            }
        }

      graphicsContext.drawLayer { backgroundGraphicsContext in
        for rowDrawRun in rowDrawRuns {
          backgroundGraphicsContext.fill(
            Path(rowDrawRun.frame),
            with: .color(rowDrawRun.backgroundColor.swiftUI)
          )
        }
      }

      graphicsContext.drawLayer { foregroundGraphicsContext in
        for rowDrawRun in rowDrawRuns {
          var frame = rowDrawRun.frame
          frame.size.width = .greatestFiniteMagnitude

          foregroundGraphicsContext.draw(
            rowDrawRun.text,
            in: frame
          )
        }
      }

      if
        let cursor,
        cursor.gridID == grid.id,
        cursor.position.row < grid.cells.rowsCount,
        cursor.position.column < grid.cells.columnsCount {
        let cursorGraphicsContext = graphicsContext

        let frame = CGRect(
          origin: .init(
            x: Double(cursor.position.column) * appearance.font.cellWidth,
            y: Double(cursor.position.row) * appearance.font.cellHeight
          ),
          size: .init(
            width: appearance.font.cellWidth,
            height: appearance.font.cellHeight
          )
        )

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
    .allowsTightening(false)
  }
}
