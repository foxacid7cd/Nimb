// SPDX-License-Identifier: MIT

import CasePaths
import ComposableArchitecture
import Library
import Neovim
import Overture
import SwiftUI

@MainActor
public struct View: SwiftUI.View {
  public init(store: Store<State, Action>) {
    self.store = store
  }

  public var store: Store<State, Action>

  public var body: some SwiftUI.View {
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
            size: outerGrid.cells.size
          )
          .frame(
            width: frameWidth,
            height: frameHeight
          )

          ForEach(state.windows) { window in
            gridView(
              for: state.grids[id: window.gridID]!,
              font: font,
              size: window.frame.size
            )
            .frame(
              width: Double(window.frame.size.columnsCount) * font.cellWidth,
              height: Double(window.frame.size.rowsCount) * font.cellHeight
            )
            .offset(
              x: Double(window.frame.origin.column) * font.cellWidth,
              y: Double(window.frame.origin.row) * font.cellHeight
            )
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

  private func gridView(for grid: State.Grid, font: Neovim.Font, size: IntegerSize) -> some SwiftUI
    .View {
    let attributes = AttributeContainer([
      .font: font.nsFont,
      .foregroundColor: NSColor.systemPink,
    ])

    let rows = grid.cells.rows

    let lower = rows.startIndex
    let upper = min(lower + size.rowsCount, rows.endIndex)
    let rowAttributedStrings = rows[lower ..< upper]
      .map { rowCells in
        let lower = rowCells.startIndex
        let upper = min(lower + size.columnsCount, rowCells.endIndex)
        let string = rowCells[lower ..< upper]
          .map(\.text)
          .joined()

        return AttributedString(string, attributes: attributes)
      }

    return Canvas(opaque: true, rendersAsynchronously: true) { graphicsContext, size in
      graphicsContext.fill(
        Path(CGRect(origin: .init(), size: size)),
        with: .color(.black),
        style: .init(antialiased: false)
      )

      for (offset, rowAttributedString) in rowAttributedStrings.enumerated() {
        let frame = CGRect(
          origin: .init(
            x: 0,
            y: Double(offset) * font.cellHeight
          ),
          size: .init(
            width: size.width,
            height: font.cellHeight
          )
        )

        graphicsContext.draw(Text(rowAttributedString), in: frame)
      }
    }
  }
}
