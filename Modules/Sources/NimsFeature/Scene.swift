// SPDX-License-Identifier: MIT

import Clocks
import ComposableArchitecture
import InstanceFeature
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
          store.scope(
            state: \.instance,
            action: Nims.Action.instance(action:)
          ),
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

          let cursorBlinks = suspendingClock.timer(interval: .milliseconds(500))
            .map { _ in () }
            .erasedToAsyncStream

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
                cursorBlinks: cursorBlinks
              )
            )

        default:
          break
        }
      }
    }

    @Environment(\.scenePhase)
    private var scenePhase: ScenePhase

    @Environment(\.suspendingClock)
    private var suspendingClock: any Clock<Duration>
  }
}
