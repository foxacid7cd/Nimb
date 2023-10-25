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
      setupSecondaryWindowControllers()
      setupKeyDownLocalMonitor()
    }
  }

  private var store: Store?
  private var mainMenuController: MainMenuController?
  private var mainWindowController: MainWindowController?
  private var msgShowsWindowController: MsgShowsWindowController?
  private var cmdlinesWindowController: CmdlinesWindowController?
  private var popupmenuWindowController: PopupmenuWindowController?

  private func setupStore() async {
    let initialOuterGridSize: IntegerSize = if
      let rowsCount = UserDefaults.standard.value(forKey: "rowsCount") as? Int,
      let columnsCount = UserDefaults.standard.value(forKey: "columnsCount") as? Int
    {
      .init(columnsCount: columnsCount, rowsCount: rowsCount)
    } else {
      .init(columnsCount: 110, rowsCount: 34)
    }

    let font: NimsFont = if
      let name = UserDefaults.standard.value(forKey: "fontName") as? String,
      let size = UserDefaults.standard.value(forKey: "fontSize") as? Double,
      let nsFont = NSFont(name: name, size: size)
    {
      .init(nsFont)
    } else {
      .init()
    }

    let instance = await Task { @NeovimActor in
      Instance(
        neovimRuntimeURL: Bundle.main.resourceURL!.appending(path: "nvim/share/nvim/runtime"),
        initialOuterGridSize: initialOuterGridSize
      )
    }.value

    let store = Store(instance: instance, font: font) { [weak self] store, stateUpdates in
      self?.mainWindowController?.render(stateUpdates)
      self?.msgShowsWindowController?.render(stateUpdates)
      self?.cmdlinesWindowController?.render(stateUpdates)
      self?.popupmenuWindowController?.render(stateUpdates)

      if stateUpdates.updatedLayoutGridIDs.contains(Grid.OuterID) {
        let outerGridSize = store.state.outerGrid!.size
        Task { @MainActor in
          UserDefaults.standard.setValue(outerGridSize.rowsCount, forKey: "rowsCount")
          UserDefaults.standard.setValue(outerGridSize.columnsCount, forKey: "columnsCount")
        }
      }
    }
    self.store = store

    Task {
      let instanceResult = await store.instance.result

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
      msgShowsWindow: msgShowsWindowController!.window!,
      gridWindowFrameTransformer: self
    )
  }

  private func setupKeyDownLocalMonitor() {
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      guard 
        let self,
        mainWindowController!.window!.isKeyWindow,
        !event.modifierFlags.contains(.command)
      else {
        return event
      }

      let keyPress = KeyPress(event: event)

      Task { @MainActor [self] in
        self.store!.scheduleHideMsgShowsIfPossible()
        await self.store!.instance.report(keyPress: keyPress)
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
