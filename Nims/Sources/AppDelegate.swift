// SPDX-License-Identifier: MIT

import AppKit
import CustomDump
import Library
import RollbarNotifier

@MainActor
public class AppDelegate: NSObject, NSApplicationDelegate {
  override public nonisolated init() {
    super.init()
  }

  public func applicationDidFinishLaunching(_: Notification) {
    #if DEBUG
    #else
      let config = RollbarConfig.mutableConfig(withAccessToken: "714fb2995cb34335a86187d3a72a818c")
      Rollbar.initWithConfiguration(config)
    #endif

    Task {
      await setupStore()
      setupMainMenuController()
      runStateUpdatesTask()
    }
  }

  private var store: Store?
  private var stateUpdatesTask: Task<Void, Never>?
  private var mainMenuController: MainMenuController?
  private var mainWindowController: MainWindowController?
  private var settingsWindowController: SettingsWindowController?

  private func setupStore() async {
    let instance = await Instance(
      neovimRuntimeURL: Bundle.main.resourceURL!.appending(path: "nvim/share/nvim/runtime"),
      initialOuterGridSize: UserDefaults.standard.outerGridSize
    )

    store = .init(
      instance: instance,
      debug: UserDefaults.standard.debug,
      font: UserDefaults.standard.appKitFont.map(Font.init) ?? .init()
    )
  }

  private func setupMainMenuController() {
    mainMenuController = MainMenuController(store: store!)
    mainMenuController!.settingsClicked = { [unowned self] in
      if settingsWindowController == nil {
        settingsWindowController = .init(store: store!)
      }
      settingsWindowController!.showWindow(nil)
    }
    NSApplication.shared.mainMenu = mainMenuController!.menu
  }

  private func setupMainWindowController(initialOuterGridSize: IntegerSize) {
    mainWindowController = MainWindowController(
      store: store!,
      minOuterGridSize: .init(columnsCount: 80, rowsCount: 24),
      initialOuterGridSize: initialOuterGridSize
    )
  }

  private func runStateUpdatesTask() {
    stateUpdatesTask = Task { [weak self, store] in
      do {
        for try await stateUpdates in store! {
          guard !Task.isCancelled, let self else {
            return
          }
          if mainWindowController == nil, !stateUpdates.gridsUpdates.isEmpty {
            if case let (gridID, update) = stateUpdates.gridsUpdates[0], gridID == Grid.OuterID, case let .resize(size) = update {
              setupMainWindowController(initialOuterGridSize: size)

            } else {
              Loggers.problems.error("first grid event is not resize outer grid \(String(customDumping: stateUpdates.gridsUpdates[0]))")
            }
          }
          if stateUpdates.isFontUpdated {
            UserDefaults.standard.appKitFont = store!.state.font.appKit()
          }
          if stateUpdates.isDebugUpdated {
            UserDefaults.standard.debug = store!.state.debug
          }
          try await mainWindowController!.render(stateUpdates)
        }
      } catch {
        let alert = NSAlert(error: error)
        alert.informativeText = String(customDumping: error)
        alert.runModal()
      }
      NSApplication.shared.terminate(nil)
    }
  }
}
