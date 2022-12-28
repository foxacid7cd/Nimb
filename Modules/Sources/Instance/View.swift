//
//  View.swift
//
//
//  Created by Yevhenii Matviienko on 28.12.2022.
//

import CasePaths
import ComposableArchitecture
import NimsModel
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
      if let font = state.font, let outerGridSize = state.outerGridSize {
        ZStack(alignment: .topLeading) {
          ForEach(state.grids) { grid in
            Canvas { graphicsContext, size in
              let rect = CGRect(origin: .init(), size: size)
              graphicsContext.fill(Path(rect), with: .color(grid.id.isOuter ? .orange : .cyan))
            }
            .frame(
              width: Double(grid.cells.columnsCount) * font.cellWidth,
              height: Double(grid.cells.rowsCount) * font.cellHeight
            )
            .zIndex(Double(state.grids.index(id: grid.id)!))
          }
        }
        .frame(
          width: Double(outerGridSize.columnsCount) * font.cellWidth,
          height: Double(outerGridSize.rowsCount) * font.cellHeight
        )

      } else {
        EmptyView()
      }
    }
  }
}
