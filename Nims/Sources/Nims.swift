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
  @Environment(\.scenePhase)
  var scenePhase: ScenePhase

  private var store = StoreOf<Reducer>(
    initialState: Reducer.State(instance: nil),
    reducer: Reducer()
  )

  var body: some Scene {
    WindowGroup {
      IfLetStore(store.scope(state: \.instance)) { instanceStore in
        InstanceView(
          store: instanceStore
        )
      }
    }
    .windowResizability(.contentSize)
    .onChange(of: scenePhase) { newValue in
      switch newValue {
      case .active:
        break

      default:
        break
      }
    }
  }
}
