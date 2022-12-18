//
//  Nims.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 16.12.2022.
//

import ComposableArchitecture
import SwiftUI

@MainActor
@main struct Nims: App {
  private var store = StoreOf<Reducer>(
    initialState: Reducer.State(
      font: .init(
        .init(name: "MesloLGS NF", size: 13)!
      ),
      grids: [
        .init(
          id: 1,
          cells: .init(
            size: .init(columnsCount: 80, rowsCount: 24),
            repeatingElement: .init(text: " ", highlightID: .default)
          )
        )
      ]
    ),
    reducer: Reducer()
  )

  var body: some Scene {
    WindowGroup {
      Multigrid(store: store)
    }
    .windowResizability(.contentSize)
    .windowToolbarStyle(.unified(showsTitle: true))
  }
}
