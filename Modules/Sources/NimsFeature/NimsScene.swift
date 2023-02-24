// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import Clocks
import ComposableArchitecture
import InstanceFeature
import Library
import Neovim
import SwiftUI

public struct NimsScene: SwiftUI.Scene {
  public init(store: StoreOf<Nims>) {
    self.store = store
  }

  public var store: StoreOf<Nims>

  public var body: some Scene {
    WindowGroup(id: "main") {
      IfLetStore(
        store.scope(
          state: \.instanceState,
          action: Nims.Action.instance(action:)
        )
      ) { instanceStore in
        IfLetStore(
          instanceStore.scope(state: \.outerGrid)
        ) { _ in
          WithViewStore(
            instanceStore,
            observe: { $0 },
            removeDuplicates: {
              $0.instanceUpdateFlag == $1.instanceUpdateFlag
            }
          ) { viewStore in
            InstanceView(
              store: instanceStore,
              reportMouseEvent: { mouseEvent in
                Task { await reportMouseEvent(mouseEvent) }
              }
            )
            .navigationTitle(viewStore.title ?? "Nims")
            .transformEnvironment(\.nimsAppearance) { nimsAppearance in
              nimsAppearance.font = viewStore.font
              nimsAppearance.highlights = viewStore.highlights

              viewStore.defaultForegroundColor
                .map { nimsAppearance.defaultForegroundColor = $0 }

              viewStore.defaultBackgroundColor
                .map { nimsAppearance.defaultBackgroundColor = $0 }

              viewStore.defaultSpecialColor
                .map { nimsAppearance.defaultSpecialColor = $0 }
            }
          }
        }
      }
    }
    .windowResizability(.contentSize)
    .onChange(of: scenePhase) { newValue in
      switch newValue {
      case .active:
        let keyPresses = AsyncStream<KeyPress> { continuation in
          let eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) {
              return event
            }

            let keyPress = KeyPress(event: event)
            continuation.yield(keyPress)

            return nil
          }

          continuation.onTermination = { termination in
            switch termination {
            case .cancelled:
              if let eventMonitor {
                NSEvent.removeMonitor(eventMonitor)
              }

            default:
              break
            }
          }
        }

        ViewStore(store.stateless)
          .send(
            .createInstance(
              mouseEvents: mouseEvents,
              keyPresses: keyPresses
            )
          )

      default:
        break
      }
    }
  }

  private let (reportMouseEvent, mouseEvents) = AsyncChannel<MouseEvent>.pipe()

  @Environment(\.scenePhase)
  private var scenePhase: ScenePhase
}
