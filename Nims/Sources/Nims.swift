// SPDX-License-Identifier: MIT

import Clocks
import ComposableArchitecture
import Neovim
import SwiftUI

@main
struct Nims: App {
  var body: some Scene {
    WindowGroup {
      WithViewStore(
        store,
        observe: { $0 },
        removeDuplicates: { $0.instanceUpdateFlag == $1.instanceUpdateFlag }
      ) { state in
        if let instanceState = state.instance {
          Text(verbatim: "\(instanceState)")
            .fixedSize()
            .frame(width: 640, height: 480, alignment: .topLeading)
        }
      }
    }
    .onChange(of: scenePhase) { newValue in
      switch newValue {
      case .active:
        let viewStore = ViewStore(store.stateless)
        viewStore.send(.createNeovimInstance)

      default:
        break
      }
    }
  }

  @Environment(\.scenePhase)
  private var scenePhase: ScenePhase

  private var store = StoreOf<MainReducer>(
    initialState: .init(),
    reducer: MainReducer()
  )
}
