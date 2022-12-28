//
//  View.swift
//
//
//  Created by Yevhenii Matviienko on 28.12.2022.
//

import CasePaths
import ComposableArchitecture
import Library
import Neovim
import Overture
import SwiftUI

@MainActor
public struct View: SwiftUI.View {
  public var store: Store<State, Action>

  public init(store: Store<State, Action>) {
    self.store = store
  }

  public var body: some SwiftUI.View {
    WithViewStore(
      store,
      observe: { $0 }
    ) { state in
      if let font = state.font, let outerGrid = state.outerGrid {
        let frameWidth = Double(outerGrid.cells.columnsCount) * font.cellWidth
        let frameHeight = Double(outerGrid.cells.rowsCount) * font.cellHeight

        ZStack(alignment: .topLeading) {
          canvas(
            for: outerGrid,
            font: font,
            size: outerGrid.cells.size
          )
          .frame(
            width: frameWidth,
            height: frameHeight)

          ForEach(state.windows) { window in
            canvas(
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
              y: Double(window.frame.origin.row) * font.cellHeight)
          }
        }
        .frame(
          width: frameWidth,
          height: frameHeight)

      } else {
        EmptyView()
      }
    }
  }

  private func canvas(for grid: State.Grid, font: Neovim.Font, size: IntegerSize)
    -> Canvas<EmptyView>
  {
    let attributes = AttributeContainer([
      .font: font.nsFont,
      .foregroundColor: NSColor.systemPink,
    ])

    let rows = grid.cells.rows

    let lower = rows.startIndex
    let upper = rows.index(lower, offsetBy: size.rowsCount)
    let rowAttributedStrings = rows[lower..<upper]
      .map { rowCells in
        let string: String

        if rowCells.isEmpty {
          string = ""

        } else {
          let lower = rowCells.startIndex
          let upper = rowCells.index(lower, offsetBy: size.columnsCount)
          string = rowCells[lower..<upper]
            .map { $0.text }
            .joined()
        }

        return AttributedString(string, attributes: attributes)
      }

    return .init { graphicsContext, size in
      for (offset, rowAttributedString) in rowAttributedStrings.enumerated() {
        let frame = CGRect(
          origin: .init(
            x: 0,
            y: Double(offset) * font.cellHeight),
          size: .init(
            width: size.width,
            height: font.cellHeight))

        graphicsContext.draw(Text(rowAttributedString), in: frame)
      }
    }
  }
}
