//
//  Nims.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 16.12.2022.
//

import ComposableArchitecture
import Instance
import SwiftUI

@MainActor
@main struct Nims: App {
  @Environment(\.scenePhase)
  var scenePhase: ScenePhase

  private var store = StoreOf<Reducer>(
    initialState: .init(),
    reducer: Reducer()
  )

  var body: some Scene {
    WindowGroup {
      ForEachStore(
        store.scope(
          state: \.instances,
          action: Action.instance(id:action:))
      ) { Instance.View(store: $0) }
    }
    .windowResizability(.contentSize)
    .onChange(of: scenePhase) { newValue in
      switch newValue {
      case .active:
        ViewStore(store)
          .send(.createInstance)

      default:
        break
      }
    }
  }
}
