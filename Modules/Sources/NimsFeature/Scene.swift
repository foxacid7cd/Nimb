// SPDX-License-Identifier: MIT

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

    public struct InstanceViewModel: Equatable {
      public init(
        font: Instance.State.Font,
        defaultForegroundColor: Instance.State.Color,
        defaultBackgroundColor: Instance.State.Color,
        defaultSpecialColor: Instance.State.Color,
        outerGridSize: IntegerSize,
        highlights: IdentifiedArrayOf<Instance.State.Highlight>,
        title: String
      ) {
        self.font = font
        self.defaultForegroundColor = defaultForegroundColor
        self.defaultBackgroundColor = defaultBackgroundColor
        self.defaultSpecialColor = defaultSpecialColor
        self.outerGridSize = outerGridSize
        self.highlights = highlights
        self.title = title
      }

      public init?(instance: Instance.State) {
        guard
          let font = instance.font ?? instance.defaultFont,
          let defaultHighlight = instance.highlights[id: .default],
          let defaultForegroundColor = defaultHighlight.foregroundColor,
          let defaultBackgroundColor = defaultHighlight.backgroundColor,
          let defaultSpecialColor = defaultHighlight.specialColor,
          let outerGrid = instance.outerGrid,
          let title = instance.title
        else {
          return nil
        }

        self.init(
          font: font,
          defaultForegroundColor: defaultForegroundColor,
          defaultBackgroundColor: defaultBackgroundColor,
          defaultSpecialColor: defaultSpecialColor,
          outerGridSize: outerGrid.cells.size,
          highlights: instance.highlights,
          title: title
        )
      }

      public var font: Instance.State.Font
      public var defaultForegroundColor: Instance.State.Color
      public var defaultBackgroundColor: Instance.State.Color
      public var defaultSpecialColor: Instance.State.Color
      public var highlights: IdentifiedArrayOf<Instance.State.Highlight>
      public var outerGridSize: IntegerSize
      public var title: String
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
                WithViewStore($0, observe: { $0 }) { instanceViewModel in
                  Instance.View(
                    font: instanceViewModel.font,
                    defaultForegroundColor: instanceViewModel.defaultForegroundColor,
                    defaultBackgroundColor: instanceViewModel.defaultBackgroundColor,
                    defaultSpecialColor: instanceViewModel.defaultSpecialColor,
                    outerGridSize: instanceViewModel.outerGridSize,
                    highlights: instanceViewModel.highlights,
                    store: instanceStore
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
                keyPresses: keyPresses
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
