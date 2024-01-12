// SPDX-License-Identifier: MIT

import AppKit
import CustomDump
import Library
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  override nonisolated init() {
    super.init()
  }

  func applicationDidFinishLaunching(_: Notification) {
    Task {
      await setupStore()
      setupMainMenuController()
      showMainWindowController()
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

  private func showMainWindowController() {
    mainWindowController = MainWindowController(
      store: store!,
      minOuterGridSize: .init(columnsCount: 80, rowsCount: 24)
    )
  }

  private func runStateUpdatesTask() {
    stateUpdatesTask = Task { [weak self, store] in
      do {
        for try await stateUpdates in store! {
          guard !Task.isCancelled, let self else {
            return
          }
          if stateUpdates.isOuterGridLayoutUpdated {
            UserDefaults.standard.outerGridSize = store!.state.outerGrid!.size
          }
          if stateUpdates.isFontUpdated {
            UserDefaults.standard.appKitFont = store!.state.font.appKit()
          }
          if stateUpdates.isDebugUpdated {
            UserDefaults.standard.debug = store!.state.debug
          }
          mainWindowController!.render(stateUpdates)
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
