// SPDX-License-Identifier: MIT

import AppKit
import CustomDump
import Library
import Neovim
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private var store: Store?
  private var mainWindowController: MainWindowController?
  private var msgShowsWindowController: MsgShowsWindowController?
  private var cmdlinesWindowController: CmdlinesWindowController?

  func applicationDidFinishLaunching(_: Notification) {
    setupStore()
    setupMainMenu()
    showMainWindowController()
    setupSecondaryWindowControllers()
    setupKeyDownLocalMonitor()
  }

  private func setupStore() {
    let instance = Instance()
    store = Store(instance: instance)

    if let sfMonoNFM = NSFont(name: "SFMono Nerd Font Mono", size: 12) {
      let font = NimsFont(sfMonoNFM)
      store!.set(font: font)
    }

    Task {
      for await updates in store!.stateUpdatesStream() {
        if updates.isTitleUpdated {
          mainWindowController?.windowTitle = store!.title ?? ""
        }
        if updates.isAppearanceUpdated {
          mainWindowController?.windowBackgroundColor = store!.appearance.defaultBackgroundColor.appKit
        }
      }
    }

    Task {
      if let finishedResult = await instance.finishedResult() {
        NSAlert(error: finishedResult)
          .runModal()
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
    let mainViewController = MainViewController(store: store!)

    mainWindowController = MainWindowController(store: store!, viewController: mainViewController)
    mainWindowController!.showWindow(nil)
    mainWindowController!.windowBackgroundColor = store!.appearance.defaultBackgroundColor.appKit
  }

  private func setupSecondaryWindowControllers() {
    msgShowsWindowController = MsgShowsWindowController(store: store!, parentWindow: mainWindowController!.window!)
    cmdlinesWindowController = CmdlinesWindowController(store: store!, parentWindow: mainWindowController!.window!)
  }

  private func setupKeyDownLocalMonitor() {
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
      let keyPress = KeyPress(event: event)
      let store = self.store!

      Task {
        await store.report(keyPress: keyPress)
      }

      return nil
    }
  }
}
