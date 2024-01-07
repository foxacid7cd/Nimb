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

  private func setupStore() async {
    let instance = await Instance(
      neovimRuntimeURL: Bundle.main.resourceURL!.appending(path: "nvim/share/nvim/runtime"),
      initialOuterGridSize: UserDefaults.standard.outerGridSize
    )

    let font: Font = if
      let name = UserDefaults.standard.fontName,
      let size = UserDefaults.standard.fontSize,
      let nsFont = NSFont(name: name, size: size)
    {
      .init(nsFont)
    } else {
      .init()
    }
    store = .init(instance: instance, debug: UserDefaults.standard.debug, font: font)
  }

  private func setupMainMenuController() {
    mainMenuController = MainMenuController(store: store!)
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
          guard !Task.isCancelled else {
            return
          }

          self?.mainWindowController?.render(stateUpdates)

          if stateUpdates.isOuterGridLayoutUpdated {
            UserDefaults.standard.outerGridSize = store!.state.outerGrid!.size
          }

          if stateUpdates.isFontUpdated {
            UserDefaults.standard.fontSize = store!.state.font.appKit().pointSize
            UserDefaults.standard.fontName = store!.state.font.appKit().fontName
          }

          if stateUpdates.isDebugUpdated {
            UserDefaults.standard.debug = store!.state.debug
          }
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
