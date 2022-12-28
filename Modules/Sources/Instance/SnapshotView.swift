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
      if let font = state.font, let outerGrid = state.outerGrid {
        let frameWidth = Double(outerGrid.cells.columnsCount) * font.cellWidth
        let frameHeight = Double(outerGrid.cells.rowsCount) * font.cellHeight

        ZStack(alignment: .topLeading) {
          gridView(
            for: outerGrid,
            font: font,
            size: outerGrid.cells.size,
            cursor: state.cursor
          )
          .frame(
            width: frameWidth,
            height: frameHeight
          )
          .zIndex(0)

          ForEach(state.windows) { window in
            if !window.isHidden {
              gridView(
                for: state.grids[id: window.gridID]!,
                font: font,
                size: window.frame.size,
                cursor: state.cursor
              )
              .frame(
                width: Double(window.frame.size.columnsCount) * font.cellWidth,
                height: Double(window.frame.size.rowsCount) * font.cellHeight
              )
              .offset(
                x: Double(window.frame.origin.column) * font.cellWidth,
                y: Double(window.frame.origin.row) * font.cellHeight
              )
              .zIndex(Double(window.zIndex) / 1000)

            } else {
              EmptyView()
            }
          }

          ForEach(state.floatingWindows) { floatingWindow in
            if !floatingWindow.isHidden {
              let grid = state.grids[id: floatingWindow.gridID]!

              gridView(
                for: grid,
                font: font,
                size: grid.cells.size,
                cursor: state.cursor
              )
              .frame(
                width: Double(grid.cells.size.columnsCount) * font.cellWidth,
                height: Double(grid.cells.size.rowsCount) * font.cellHeight
              )
              .offset(
                x: Double(floatingWindow.anchorColumn) * font.cellWidth,
                y: Double(floatingWindow.anchorRow) * font.cellHeight
              )
              .zIndex(Double(floatingWindow.zIndex) / 1000 + 1_000_000)

            } else {
              EmptyView()
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

  private func gridView(for grid: State.Grid, font: Neovim.Font, size: IntegerSize, cursor: State.Cursor?) -> some View {
    Canvas(rendersAsynchronously: true) { graphicsContext, _ in
      let rowScale = 1 / Double(grid.rowHighlightChunks.count)

      let rowDrawRuns: [(frame: CGRect, backgroundColor: SwiftUI.Color, text: Text)] = grid.rowHighlightChunks
        .enumerated()
        .flatMap { row, highlightChunks in
          let hue = Double(row) * rowScale
          let chunkScale = 1 / Double(highlightChunks.count)

          return highlightChunks
            .enumerated()
            .map { offset, highlightChunk in
              let frame = CGRect(
                origin: .init(
                  x: Double(highlightChunk.originColumn) * font.cellWidth,
                  y: Double(row) * font.cellHeight
                ),
                size: .init(
                  width: Double(highlightChunk.columnsCount) * font.cellWidth,
                  height: font.cellHeight
                )
              )

              let backgroundColor = SwiftUI.Color(
                hue: 0.6 + Double(highlightChunk.highlightID.rawValue / 111),
                saturation: 0.5 + Double(highlightChunk.highlightID.rawValue / 221),
                brightness: 0.05
              )

              let text = Text(highlightChunk.text)
                .font(.init(font.nsFont))
                .foregroundColor(
                  .init(
                    hue: hue,
                    saturation: 1,
                    brightness: 0.8 + Double(offset) * chunkScale / 5
                  )
                )

              return (frame, backgroundColor, text)
            }
        }

      graphicsContext.drawLayer { backgroundGraphicsContext in
        for rowDrawRun in rowDrawRuns {
          backgroundGraphicsContext.fill(
            Path(rowDrawRun.frame),
            with: .color(rowDrawRun.backgroundColor)
          )
        }
      }

      graphicsContext.drawLayer { foregroundGraphicsContext in
        for rowDrawRun in rowDrawRuns {
          foregroundGraphicsContext.draw(
            rowDrawRun.text,
            in: rowDrawRun.frame
          )
        }
      }

      if
        let cursor,
        cursor.gridID == grid.id,
        cursor.position.row < grid.cells.rowsCount,
        cursor.position.column < grid.cells.columnsCount
      {
        let cursorGraphicsContext = graphicsContext

        let frame = CGRect(
          origin: .init(
            x: Double(cursor.position.column) * font.cellWidth,
            y: Double(cursor.position.row) * font.cellHeight
          ),
          size: .init(
            width: font.cellWidth,
            height: font.cellHeight
          )
        )

        cursorGraphicsContext.fill(
          Path(frame),
          with: .color(.white)
        )

        let cell = grid.cells[cursor.position]

        let text = Text(cell.text)
          .font(.init(font.nsFont))
          .foregroundColor(.black)

        cursorGraphicsContext.draw(text, in: frame)
      }
    }
  }
}
