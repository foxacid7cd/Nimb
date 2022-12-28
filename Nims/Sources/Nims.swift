// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import ComposableArchitecture
import Instance
import Neovim
import SwiftUI

@main
struct Nims: App {
  @Environment(\.scenePhase)
  var scenePhase: ScenePhase

  var body: some Scene {
    Window("Nims", id: "Main") {
      IfLetStore(
        store.scope(state: \.instance, action: Action.instance(action:)),
        then: { Instance.View(store: $0) }
      )
    }
    .windowResizability(.contentSize)
    .onChange(of: scenePhase) { newValue in
      switch newValue {
      case .active:
        let keyPresses = AsyncStream<KeyPress> { continuation in
          let eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let keyPress = KeyPress(event: event)
            continuation.yield(keyPress)

            return nil
          }

          continuation.onTermination = { termination in
            switch termination {
            case .cancelled:
              continuation.finish()

            case .finished:
              if let eventMonitor {
                NSEvent.removeMonitor(eventMonitor)
              }

            @unknown default:
              break
            }
          }
        }

        ViewStore(store)
          .send(.createInstance(keyPresses: keyPresses))

      default:
        break
      }
    }
  }

  private var store = StoreOf<Reducer>(
    initialState: .init(),
    reducer: Reducer()
  )
}
