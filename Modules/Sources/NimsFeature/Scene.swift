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
      SwiftUI.WindowGroup("Nims", id: "main") {
        IfLetStore(
          store.scope(
            state: \.instanceState,
            action: Action.instance(action:)
          ),
          then: { instanceStateStore in
            IfLetStore(
              instanceStateStore.scope(
                state: makeModel(for:)
              ),
              then: { modelStore in
                WithViewStore(
                  modelStore,
                  observe: { $0 },
                  removeDuplicates: {
                    $0.instanceState.instanceUpdateFlag == $1.instanceState.instanceUpdateFlag
                  }
                ) { modelViewStore in
                  let model = modelViewStore.state

                  InstanceView(
                    store: modelStore.scope(
                      state: \.instanceViewModel,
                      action: Instance.Action.view(action:)
                    )
                  )
                  .navigationTitle(model.title)
                  .environment(\.nimsAppearance, model.nimsAppearance)
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
                arguments: ["-u", "/Users/foxacid/.local/share/lunarvim/lvim/init.lua"],
                environmentOverlay: [
                  "LUNARVIM_RUNTIME_DIR": "/Users/foxacid/.local/share/lunarvim",
                  "LUNARVIM_CONFIG_DIR": "/Users/foxacid/.config/lvim",
                  "LUNARVIM_CACHE_DIR": "/Users/foxacid/.cache/lvim",
                  "LUNARVIM_BASE_DIR": "/Users/foxacid/.local/share/lunarvim/lvim",
                ],
                mouseEvents: mouseEvents,
                keyPresses: keyPresses
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

    private struct Model {
      init(
        instanceState: InstanceState,
        nimsAppearance: NimsAppearance,
        instanceViewModel: InstanceView.Model,
        title: String
      ) {
        self.instanceState = instanceState
        self.nimsAppearance = nimsAppearance
        self.instanceViewModel = instanceViewModel
        self.title = title
      }

      var instanceState: Instance.State
      var nimsAppearance: NimsAppearance
      var instanceViewModel: InstanceView.Model
      var title: String
    }

    private func makeModel(for instanceState: InstanceState) -> Model? {
      guard let nimsAppearance = makeNimsAppearance(from: instanceState), let instanceViewModel = makeInstanceViewModel(from: instanceState), let title = instanceState.title else {
        return nil
      }

      return .init(
        instanceState: instanceState,
        nimsAppearance: nimsAppearance,
        instanceViewModel: instanceViewModel,
        title: title
      )
    }

    private func makeNimsAppearance(from instanceState: InstanceState) -> NimsAppearance? {
      guard let defaultForegroundColor = instanceState.defaultForegroundColor, let defaultBackgroundColor = instanceState.defaultBackgroundColor, let defaultSpecialColor = instanceState.defaultSpecialColor else {
        return nil
      }

      return .init(
        font: instanceState.font,
        highlights: instanceState.highlights,
        defaultForegroundColor: defaultForegroundColor,
        defaultBackgroundColor: defaultBackgroundColor,
        defaultSpecialColor: defaultSpecialColor
      )
    }

    private func makeInstanceViewModel(from instanceState: InstanceState) -> InstanceView.Model? {
      guard let outerGrid = instanceState.grids[.outer], let modeInfo = instanceState.modeInfo, let mode = instanceState.mode else {
        return nil
      }

      return InstanceView.Model(
        outerGridSize: outerGrid.cells.size,
        modeInfo: modeInfo,
        mode: mode,
        tabline: instanceState.tabline,
        grids: instanceState.grids,
        windows: instanceState.windows,
        floatingWindows: instanceState.floatingWindows,
        cursor: instanceState.cursor,
        cmdlines: instanceState.cmdlines,
        cmdlineUpdateFlag: instanceState.cmdlineUpdateFlag,
        gridsLayoutUpdateFlag: instanceState.gridsLayoutUpdateFlag,
        reportMouseEvent: { mouseEvent in
          Task {
            await self.mouseEventHandler(mouseEvent)
          }
        },
        cursorBlinkingPhase: instanceState.cursorBlinkingPhase
      )
    }
  }
}
