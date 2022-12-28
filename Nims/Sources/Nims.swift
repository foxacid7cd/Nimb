//
//  Nims.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 16.12.2022.
//

import AsyncAlgorithms
import ComposableArchitecture
import Instance
import Neovim
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

          continuation.onTermination = { _ in
            if let eventMonitor {
              NSEvent.removeMonitor(eventMonitor)
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
}
