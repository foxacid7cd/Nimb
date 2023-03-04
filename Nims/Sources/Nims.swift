// SPDX-License-Identifier: MIT

import AsyncAlgorithms
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
              removeDuplicates: { lhs, rhs in
                guard
                  lhs.titleUpdateFlag == rhs.titleUpdateFlag,
                  lhs.appearanceUpdateFlag == rhs.appearanceUpdateFlag
                else {
                  return false
                }

                return true
              }
            ) { runningState in
              RunningInstanceView(
                store: runningStore,
                reportMouseEvent: { mouseEvent in
                  Task {
                    await reportMouseEvent(mouseEvent)
                  }
                }
              )
              .navigationTitle(runningState.title ?? "")
              .environment(\.appearance, runningState.appearance)
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
        let keyPresses = AsyncStream<KeyPress> { continuation in
          NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) {
              return event
            }

            let keyPress = KeyPress(event: event)
            continuation.yield(keyPress)

            return nil
          }
        }

        ViewStore(store.stateless)
          .send(
            .createNeovimInstance(
              keyPresses: keyPresses,
              mouseEvents: mouseEvents
            )
          )

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
  private let (reportMouseEvent, mouseEvents) = AsyncChannel<MouseEvent>.pipe()
}
