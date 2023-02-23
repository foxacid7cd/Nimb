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
          store.scope(
            state: \.instanceState,
            action: Action.instance(action:)
          ),
          then: { instanceStateStore in
            IfLetStore(
              instanceStateStore.scope(
                state: Model.init(instanceState:)
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
        var eventMonitor: Any?

        switch newValue {
        case .active:
          let viewStore = ViewStore(
            store.scope(state: \.instanceState?.process),
            observe: { $0 },
            removeDuplicates: {
              $0.map(ObjectIdentifier.init(_:)) == $1.map(ObjectIdentifier.init(_:))
            }
          )

          viewStore
            .send(
              .createInstance(
                arguments: ["-u", "/Users/foxacid/.local/share/lunarvim/lvim/init.lua"],
                environmentOverlay: [
                  "LUNARVIM_RUNTIME_DIR": "/Users/foxacid/.local/share/lunarvim",
                  "LUNARVIM_CONFIG_DIR": "/Users/foxacid/.config/lvim",
                  "LUNARVIM_CACHE_DIR": "/Users/foxacid/.cache/lvim",
                  "LUNARVIM_BASE_DIR": "/Users/foxacid/.local/share/lunarvim/lvim",
                ]
              )
            )

          eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let keyPress = KeyPress(event: event)

            Task {
              do {
                _ = try await viewStore.state?.api.nvimInput(
                  keys: keyPress.makeNvimKeyCode()
                )
                .get()

              } catch {
                assertionFailure("\(error)")
              }
            }

            return nil
          }

        case .background,
             .inactive:
          if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
          }

        default:
          break
        }
      }
    }

    let (mouseEventHandler, mouseEvents) = AsyncChannel<MouseEvent>.pipe()
    let (tabSelectionHandler, tabSelections) = AsyncChannel<References.Tabpage>.pipe()

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

      init?(instanceState: InstanceState?) {
        guard let instanceState, let nimsAppearance = Model.makeNimsAppearance(from: instanceState), let instanceViewModel = Model.makeInstanceViewModel(from: instanceState), let title = instanceState.title else {
          return nil
        }

        self.init(
          instanceState: instanceState,
          nimsAppearance: nimsAppearance,
          instanceViewModel: instanceViewModel,
          title: title
        )
      }

      private static func makeNimsAppearance(from instanceState: InstanceState) -> NimsAppearance? {
        guard let font = instanceState.font, let defaultForegroundColor = instanceState.defaultForegroundColor, let defaultBackgroundColor = instanceState.defaultBackgroundColor, let defaultSpecialColor = instanceState.defaultSpecialColor else {
          return nil
        }

        return .init(
          font: font,
          highlights: instanceState.highlights,
          defaultForegroundColor: defaultForegroundColor,
          defaultBackgroundColor: defaultBackgroundColor,
          defaultSpecialColor: defaultSpecialColor
        )
      }

      private static func makeInstanceViewModel(from instanceState: InstanceState) -> InstanceView.Model? {
        guard let outerGrid = instanceState.grids[id: .outer], let modeInfo = instanceState.modeInfo, let mode = instanceState.mode else {
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
          cursorBlinkingPhase: instanceState.cursorBlinkingPhase,
          cmdlines: instanceState.cmdlines,
          cmdlineUpdateFlag: instanceState.cmdlineUpdateFlag,
          gridsLayoutUpdateFlag: instanceState.gridsLayoutUpdateFlag
        )
      }
    }
  }
}
