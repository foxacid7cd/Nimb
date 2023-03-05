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
        let state = store!.state

        if updates.isTitleUpdated {
          mainWindowController?.windowTitle = state.title ?? ""
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

  private func showMainWindowController() {
    let mainViewController = MainViewController(store: store!)

    mainWindowController = MainWindowController(mainViewController)
    mainWindowController!.showWindow(nil)
  }

  private func setupSecondaryWindowControllers() {
    msgShowsWindowController = MsgShowsWindowController(store: store!)
    cmdlinesWindowController = CmdlinesWindowController(store: store!)
  }

  private func setupKeyDownLocalMonitor() {
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
      if event.modifierFlags.contains(.command) {
        return event
      }

      let keyPress = KeyPress(event: event)
      let store = self.store!

      Task {
        await store.report(keyPress: keyPress)
      }

      return nil
    }
  }
}
