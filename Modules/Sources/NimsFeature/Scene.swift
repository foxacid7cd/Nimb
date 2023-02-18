// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import Clocks
import ComposableArchitecture
import InstanceFeature
import Library
import Neovim
import SwiftUI

public extension Nims {
  struct Scene: SwiftUI.Scene {
    public init(_ store: StoreOf<Nims>) {
      self.store = store
    }

    public var store: StoreOf<Nims>

    public var body: some SwiftUI.Scene {
      WindowGroup {
        IfLetStore(
          store.scope(state: \.instance, action: Action.instance(action:)),
          then: { instanceStore in
            IfLetStore(
              instanceStore.scope(state: InstanceViewModel.init(instance:)),
              then: {
                WithViewStore(
                  $0,
                  observe: { $0 },
                  removeDuplicates: { $0.instanceUpdateFlag == $1.instanceUpdateFlag }
                ) { viewStore in
                  let instanceViewModel = viewStore.state

                  InstanceView(
                    model: instanceViewModel,
                    store: instanceStore,
                    mouseEventHandler: { mouseEvent in
                      Task.detached {
                        await mouseEventHandler(mouseEvent)
                      }
                    },
                    tabSelectionHandler: { reference in
                      Task.detached {
                        await tabSelectionHandler(reference)
                      }
                    }
                  )
                  .navigationTitle(instanceViewModel.title)
                }
              }
            )
          }
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
            .send(
              .createInstance(
                arguments: ["-u", "/Users/foxacid/.local/share/lunarvim/lvim/init.lua"],
                environmentOverlay: [
                  "LUNARVIM_RUNTIME_DIR": "/Users/foxacid/.local/share/lunarvim",
                  "LUNARVIM_CONFIG_DIR": "/Users/foxacid/.config/lvim",
                  "LUNARVIM_CACHE_DIR": "/Users/foxacid/.cache/lvim",
                  "LUNARVIM_BASE_DIR": "/Users/foxacid/.local/share/lunarvim/lvim",
                ],
                keyPresses: keyPresses,
                mouseEvents: mouseEvents,
                tabSelections: tabSelections
              )
            )

        default:
          break
        }
      }
    }

    private let (mouseEventHandler, mouseEvents) = AsyncChannel<MouseEvent>.pipe()
    private let (tabSelectionHandler, tabSelections) = AsyncChannel<References.Tabpage>.pipe()

    @Environment(\.scenePhase)
    private var scenePhase: ScenePhase
  }
}
