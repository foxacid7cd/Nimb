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

    public struct InstanceViewModel: Equatable {
      public init(
        font: InstanceFeature.Font,
        defaultForegroundColor: InstanceFeature.Color,
        defaultBackgroundColor: InstanceFeature.Color,
        defaultSpecialColor: InstanceFeature.Color,
        outerGridSize: IntegerSize,
        highlights: IdentifiedArrayOf<Highlight>,
        title: String,
        instanceUpdateFlag: Bool,
        modeInfo: ModeInfo
      ) {
        self.font = font
        self.defaultForegroundColor = defaultForegroundColor
        self.defaultBackgroundColor = defaultBackgroundColor
        self.defaultSpecialColor = defaultSpecialColor
        self.outerGridSize = outerGridSize
        self.highlights = highlights
        self.title = title
        self.instanceUpdateFlag = instanceUpdateFlag
        self.modeInfo = modeInfo
      }

      public init?(instance: Instance.State) {
        guard
          let font = instance.font ?? instance.defaultFont,
          let defaultHighlight = instance.highlights[id: .default],
          let defaultForegroundColor = defaultHighlight.foregroundColor,
          let defaultBackgroundColor = defaultHighlight.backgroundColor,
          let defaultSpecialColor = defaultHighlight.specialColor,
          let outerGrid = instance.outerGrid,
          let title = instance.title,
          let modeInfo = instance.modeInfo
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
          title: title,
          instanceUpdateFlag: instance.instanceUpdateFlag,
          modeInfo: modeInfo
        )
      }

      public var font: InstanceFeature.Font
      public var defaultForegroundColor: InstanceFeature.Color
      public var defaultBackgroundColor: InstanceFeature.Color
      public var defaultSpecialColor: InstanceFeature.Color
      public var highlights: IdentifiedArrayOf<Highlight>
      public var outerGridSize: IntegerSize
      public var title: String
      public var instanceUpdateFlag: Bool
      public var modeInfo: ModeInfo
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
                ) { instanceViewModel in
                  InstanceView(
                    font: instanceViewModel.font,
                    defaultForegroundColor: instanceViewModel.defaultForegroundColor,
                    defaultBackgroundColor: instanceViewModel.defaultBackgroundColor,
                    defaultSpecialColor: instanceViewModel.defaultSpecialColor,
                    outerGridSize: instanceViewModel.outerGridSize,
                    highlights: instanceViewModel.highlights,
                    store: instanceStore,
                    mouseEventHandler: { mouseEvent in
                      Task.detached {
                        await mouseEventHandler(mouseEvent)
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
                mouseEvents: mouseEvents
              )
            )

        default:
          break
        }
      }
    }

    private let (mouseEventHandler, mouseEvents) = AsyncChannel<MouseEvent>.pipe()

    @Environment(\.scenePhase)
    private var scenePhase: ScenePhase

    @Environment(\.suspendingClock)
    private var suspendingClock: any Clock<Duration>
  }
}
