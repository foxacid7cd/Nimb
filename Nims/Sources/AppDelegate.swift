// SPDX-License-Identifier: MIT

import AppKit
import CustomDump
import Library
import Neovim
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: Notification) {
    setupStore()
    setupMainMenuController()
    showMainWindowController()
    setupSecondaryWindowControllers()
    setupKeyDownLocalMonitor()
  }

  private var store: Store?
  private var mainMenuController: MainMenuController?
  private var mainWindowController: MainWindowController?
  private var msgShowsWindowController: MsgShowsWindowController?
  private var cmdlinesWindowController: CmdlinesWindowController?
  private var popupmenuWindowController: PopupmenuWindowController?

  private func setupStore() {
    let instance = Instance(
      neovimRuntimeURL: Bundle.main.resourceURL!.appending(path: "nvim/share/nvim/runtime"),
      initialOuterGridSize: .init(columnsCount: 110, rowsCount: 34)
    )
    store = Store(instance: instance) { [weak self] stateUpdates in
      guard let self else {
        return
      }
      mainMenuController?.render(stateUpdates)
      mainWindowController?.render(stateUpdates)
      msgShowsWindowController?.render(stateUpdates)
      cmdlinesWindowController?.render(stateUpdates)
      popupmenuWindowController?.render(stateUpdates)
    }

    if let sfMonoNFM = NSFont(name: "SFMono Nerd Font", size: 13) {
      let font = NimsFont(sfMonoNFM)
      store!.set(font: font)
    }

    Task {
      let instanceResult = await instance.result

      switch instanceResult {
      case .success:
        break

      case let .failure(error):
        let alert = NSAlert(error: error)
        alert.informativeText = String(customDumping: error)
        alert.runModal()
      }
    }
  }

  private func setupMainMenuController() {
    mainMenuController = MainMenuController(store: store!)
    NSApplication.shared.mainMenu = mainMenuController!.menu
  }

  private func showMainWindowController() {
    mainWindowController = MainWindowController(store: store!)
  }

  private func setupSecondaryWindowControllers() {
    msgShowsWindowController = MsgShowsWindowController(store: store!, parentWindow: mainWindowController!.window!)
    cmdlinesWindowController = CmdlinesWindowController(store: store!, parentWindow: mainWindowController!.window!)
    popupmenuWindowController = PopupmenuWindowController(
      store: store!,
      mainWindow: mainWindowController!.window!,
      cmdlinesWindow: cmdlinesWindowController!.window!,
      gridWindowFrameTransformer: self
    )
  }

  private func setupKeyDownLocalMonitor() {
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      let keyPress = KeyPress(event: event)
      if keyPress.modifierFlags.contains(.command) {
        return event
      }

      Task { @MainActor in
        guard let self, self.mainWindowController!.window!.isMainWindow else {
          return
        }

        await self.store!.report(keyPress: keyPress)
      }

      return nil
    }
  }
}

extension AppDelegate: GridWindowFrameTransformer {
  func anchorOrigin(for anchor: Popupmenu.Anchor) -> CGPoint? {
    switch anchor {
    case let .grid(gridID, gridPoint):
      mainWindowController!.point(forGridID: gridID, gridPoint: gridPoint)

    case let .cmdline(location):
      cmdlinesWindowController!.point(forCharacterLocation: location)
    }
  }
}
