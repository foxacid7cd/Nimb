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
    setupMainMenu()
    showMainWindowController()
    setupSecondaryWindowControllers()
    setupKeyDownLocalMonitor()
  }

  private var store: Store?
  private var mainWindowController: MainWindowController?
  private var msgShowsWindowController: MsgShowsWindowController?
  private var cmdlinesWindowController: CmdlinesWindowController?
  private var popupmenuWindowController: PopupmenuWindowController?

  private func setupStore() {
    let instance = Instance(initialOuterGridSize: .init(columnsCount: 90, rowsCount: 28))
    store = Store(instance: instance) { [weak self] stateUpdates in
      guard let self else {
        return
      }
      mainWindowController?.render(stateUpdates)
      msgShowsWindowController?.render(stateUpdates)
      cmdlinesWindowController?.render(stateUpdates)
      popupmenuWindowController?.render(stateUpdates)
    }

    if let sfMonoNFM = NSFont(name: "SFMono Nerd Font Mono", size: 13) {
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

  private func setupMainMenu() {
    let appMenu = NSMenu()
    let fileMenu = NSMenu(title: "File")
    let editMenu = NSMenu(title: "Edit")
    let formatMenu = NSMenu(title: "Format")
    let viewMenu = NSMenu(title: "View")
    let windowMenu = NSMenu(title: "Window")
    let helpMenu = NSMenu(title: "Help")

    let submenus = [appMenu, fileMenu, editMenu, formatMenu, viewMenu, windowMenu, helpMenu]

    let mainMenu = NSMenu()

    for submenu in submenus {
      let menuItem = NSMenuItem()
      menuItem.submenu = submenu
      mainMenu.addItem(menuItem)
    }

    NSApplication.shared.mainMenu = mainMenu
  }

  private func showMainWindowController() {
    let mainViewController = MainViewController(
      store: store!,
      initialOuterGridSize: .init(columnsCount: 90, rowsCount: 28)
    )

    mainWindowController = MainWindowController(store: store!, viewController: mainViewController)
    mainWindowController!.showWindow(nil)
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
