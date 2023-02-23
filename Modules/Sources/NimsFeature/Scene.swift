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
            state: Model.init(state:),
            action: Action.instance(action:)
          ),
          then: { modelStore in
            WithViewStore(
              modelStore,
              observe: { $0 },
              removeDuplicates: { $0.instance.instanceUpdateFlag == $1.instance.instanceUpdateFlag }
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
      .windowResizability(.contentSize)
      .onChange(of: scenePhase) { newValue in
        var eventMonitor: Any?

        switch newValue {
        case .active:
          let viewStore = ViewStore(
            store.scope(state: \.instance?.process),
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
        instance: Instance.State,
        nimsAppearance: NimsAppearance,
        instanceViewModel: InstanceView.Model,
        title: String
      ) {
        self.instance = instance
        self.nimsAppearance = nimsAppearance
        self.instanceViewModel = instanceViewModel
        self.title = title
      }

      var instance: Instance.State
      var nimsAppearance: NimsAppearance
      var instanceViewModel: InstanceView.Model
      var title: String

      init?(state: State) {
        guard let instance = state.instance, let nimsAppearance = Model.makeNimsAppearance(from: instance), let instanceViewModel = Model.makeInstanceViewModel(from: instance), let title = instance.title else {
          return nil
        }

        self.init(instance: instance, nimsAppearance: nimsAppearance, instanceViewModel: instanceViewModel, title: title)
      }

      private static func makeNimsAppearance(from instance: Instance.State) -> NimsAppearance? {
        guard let font = instance.font, let defaultForegroundColor = instance.defaultForegroundColor, let defaultBackgroundColor = instance.defaultBackgroundColor, let defaultSpecialColor = instance.defaultSpecialColor else {
          return nil
        }

        return .init(
          font: font,
          highlights: instance.highlights,
          defaultForegroundColor: defaultForegroundColor,
          defaultBackgroundColor: defaultBackgroundColor,
          defaultSpecialColor: defaultSpecialColor
        )
      }

      private static func makeInstanceViewModel(from instance: Instance.State) -> InstanceView.Model? {
        guard let outerGrid = instance.grids[id: .outer], let modeInfo = instance.modeInfo, let mode = instance.mode else {
          return nil
        }

        return InstanceView.Model(
          outerGridSize: outerGrid.cells.size,
          modeInfo: modeInfo,
          mode: mode,
          tabline: instance.tabline,
          grids: instance.grids,
          windows: instance.windows,
          floatingWindows: instance.floatingWindows,
          cursor: instance.cursor,
          cursorBlinkingPhase: instance.cursorBlinkingPhase,
          cmdlines: instance.cmdlines,
          cmdlineUpdateFlag: instance.cmdlineUpdateFlag,
          gridsLayoutUpdateFlag: instance.gridsLayoutUpdateFlag
        )
      }
    }
  }
}
