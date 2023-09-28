// SPDX-License-Identifier: MIT

import AppKit
import Carbon
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
  private var popupmenuWindowController: PopupmenuWindowController?

  func applicationDidFinishLaunching(_: Notification) {
    setupStore()
    setupMainMenu()
    showMainWindowController()
    setupSecondaryWindowControllers()
    setupKeyDownLocalMonitor()
  }

  private func setupStore() {
    let instance = Instance()
    let cursorBlinker = CursorBlinker()
    store = Store(instance: instance, cursorBlinker: cursorBlinker)

    if let sfMonoNFM = NSFont(name: "SFMono Nerd Font Mono", size: 13) {
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
        var dump = ""
        customDump(finishedResult, to: &dump, maxDepth: 10)

        let alert = NSAlert(error: finishedResult)
        alert.informativeText = dump
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
    let mainViewController = MainViewController(store: store!)

    mainWindowController = MainWindowController(store: store!, viewController: mainViewController)
    mainWindowController!.showWindow(nil)
    mainWindowController!.windowBackgroundColor = store!.appearance.defaultBackgroundColor.appKit
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
        guard let self else {
          return
        }

        if self.mainWindowController!.window!.isMainWindow || self.store!.hasModalMsgShows {
          await self.store!.report(keyPress: keyPress)

        } else if self.msgShowsWindowController!.window!.isMainWindow, keyPress.keyCode == kVK_Escape {
          self.mainWindowController!.window!.orderFront(nil)
          self.mainWindowController!.window!.makeMain()
        }
      }

      return nil
    }
  }
}

extension AppDelegate: GridWindowFrameTransformer {
  func anchorOrigin(for anchor: Popupmenu.Anchor) -> CGPoint? {
    switch anchor {
    case let .grid(gridID, gridPoint):
      mainWindowController?.point(forGridID: gridID, gridPoint: gridPoint)

    case let .cmdline(location):
      cmdlinesWindowController!.point(forCharacterLocation: location)
    }
  }
}
