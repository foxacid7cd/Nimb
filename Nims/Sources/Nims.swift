//
//  Nims.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 16.12.2022.
//

import ComposableArchitecture
import SwiftUI

@main struct Nims: App {
  private var store = StoreOf<Reducer>(
    initialState: Reducer.State(
      font: .init(name: "MesloLGS NF", size: 13),
      defaultBackgroundColor: .init(rgb: 0x000000),
      grids: []
    ),
    reducer: Reducer()
  )

  var body: some Scene {
    WindowGroup {
      WithViewStore(store, observe: ViewModel.init(state:)) { _ in
        
      }
    }
  }

  struct ViewModel: Equatable {
    init(state: Reducer.State) {}
  }
}
