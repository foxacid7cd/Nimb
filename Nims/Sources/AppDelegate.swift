// SPDX-License-Identifier: MIT

import AppKit
import CustomDump
import Library
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
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
    let initialOuterGridSize: IntegerSize = if
      let rowsCount = UserDefaults.standard.value(forKey: "rowsCount") as? Int,
      let columnsCount = UserDefaults.standard.value(forKey: "columnsCount") as? Int
    {
      .init(columnsCount: columnsCount, rowsCount: rowsCount)
    } else {
      .init(columnsCount: 110, rowsCount: 34)
    }
    let instance = await Instance(
      neovimRuntimeURL: Bundle.main.resourceURL!.appending(path: "nvim/share/nvim/runtime"),
      initialOuterGridSize: initialOuterGridSize
    )

    var debug = State.Debug()
    #if DEBUG
      if 
        let data = UserDefaults.standard.data(forKey: "debug"),
        let decoded = try? JSONDecoder().decode(State.Debug.self, from: data)
      {
        debug = decoded
      }
    #endif
    let font: NimsFont = if
      let name = UserDefaults.standard.value(forKey: "fontName") as? String,
      let size = UserDefaults.standard.value(forKey: "fontSize") as? Double,
      let nsFont = NSFont(name: name, size: size)
    {
      .init(nsFont)
    } else {
      .init()
    }
    store = .init(instance: instance, debug: debug, font: font)
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
            let outerGridSize = store!.state.outerGrid!.size
            UserDefaults.standard.setValue(outerGridSize.rowsCount, forKey: "rowsCount")
            UserDefaults.standard.setValue(outerGridSize.columnsCount, forKey: "columnsCount")
          }

          if stateUpdates.isFontUpdated {
            UserDefaults.standard.setValue(store!.state.font.appKit().pointSize, forKey: "fontSize")
          }

          #if DEBUG
            if 
              stateUpdates.isDebugUpdated,
              let encoded = try? JSONEncoder().encode(store!.state.debug)
            {
              UserDefaults.standard.setValue(encoded, forKey: "debug")
            }
          #endif
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
