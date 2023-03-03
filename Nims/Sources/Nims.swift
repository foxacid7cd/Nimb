// SPDX-License-Identifier: MIT

import CasePaths
import Clocks
import ComposableArchitecture
import CustomDump
import Neovim
import SwiftUI

@main
struct Nims: App {
  var body: some Scene {
    WindowGroup {
      ForEachStore(
        store.scope(
          state: \.instances,
          action: MainReducer.Action.instance(id:action:)
        )
      ) { store in
        SwitchStore(
          store.scope(
            state: \.phase,
            action: InstanceReducer.Action.phase
          )
        ) {
          CaseLet(
            state: /InstanceReducer.State.Phase.pending,
            action: InstanceReducer.Action.Phase.pending
          ) { _ in
            EmptyView()
          }

          CaseLet(
            state: /InstanceReducer.State.Phase.running,
            action: InstanceReducer.Action.Phase.running
          ) { runningStore in
            WithViewStore(
              runningStore,
              observe: { $0 },
              removeDuplicates: { $0.titleUpdateFlag == $1.titleUpdateFlag }
            ) { runningState in
              RunningInstanceView(store: runningStore)
                .navigationTitle(runningState.title ?? "")
            }
          }

          CaseLet(
            state: /InstanceReducer.State.Phase.finished,
            action: InstanceReducer.Action.Phase.finished
          ) { finishedStore in
            WithViewStore(
              finishedStore,
              observe: { $0 }
            ) { finishedState in
              VStack {
                Text("Neovim Instance Finished\n\(finishedState.state)")
                Button {
                  finishedState.send(.close)

                } label: {
                  Text("Close")
                }
              }
            }
          }
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
