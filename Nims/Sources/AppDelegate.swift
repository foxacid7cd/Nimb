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
      setupMainWindowEventObserving()
      setupKeyDownLocalMonitor()
      runStateUpdatesTask()
    }
  }

  private var store: Store?
  private var stateUpdatesTask: Task<Void, Never>?
  private var mainMenuController: MainMenuController?
  private var mainWindowController: MainWindowController?
  private var msgShowsWindowController: MsgShowsWindowController?
  private var cmdlinesWindowController: CmdlinesWindowController?
  private var popupmenuWindowController: PopupmenuWindowController?
  private var mainWindowEventTask: Task<Void, Never>?

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

  private func setupMainWindowEventObserving() {
    mainWindowEventTask = Task { [msgShowsWindowController, cmdlinesWindowController, popupmenuWindowController] in
      do {
        for await event in mainWindowController! {
          try Task.checkCancellation()

          switch event {
          case let .liveResizeChanged(on):
            let alphaValue: Double = on ? 0.5 : 1
            msgShowsWindowController!.window!.alphaValue = alphaValue
            cmdlinesWindowController!.window!.alphaValue = alphaValue
            popupmenuWindowController!.window!.alphaValue = alphaValue
          }
        }
      } catch {}
    }
  }

  private func setupKeyDownLocalMonitor() {
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [store] event in
      guard
        NSApplication.shared.isActive,
        !event.modifierFlags.contains(.command)
      else {
        return event
      }

      let keyPress = KeyPress(event: event)
      Task {
        await store!.report(keyPress: keyPress)
      }
      store!.scheduleHideMsgShowsIfPossible()

      return nil
    }
  }

  private func runStateUpdatesTask() {
    let store = store!

    stateUpdatesTask = Task { [weak self] in
      do {
        for try await stateUpdates in store {
          guard !Task.isCancelled else {
            return
          }

          self?.mainWindowController?.render(stateUpdates)
          self?.msgShowsWindowController?.render(stateUpdates)
          self?.cmdlinesWindowController?.render(stateUpdates)
          self?.popupmenuWindowController?.render(stateUpdates)

          if stateUpdates.isOuterGridLayoutUpdated {
            let outerGridSize = store.state.outerGrid!.size
            UserDefaults.standard.setValue(outerGridSize.rowsCount, forKey: "rowsCount")
            UserDefaults.standard.setValue(outerGridSize.columnsCount, forKey: "columnsCount")
          }

          if stateUpdates.isFontUpdated {
            UserDefaults.standard.setValue(store.state.font.nsFont().pointSize, forKey: "fontSize")
          }

          #if DEBUG
            if 
              stateUpdates.isDebugUpdated,
              let encoded = try? JSONEncoder().encode(store.state.debug)
            {
              UserDefaults.standard.setValue(encoded, forKey: "debug")
            }
          #endif
        }
      } catch {
        assertionFailure(error)
      }

      NSApplication.shared.terminate(nil)
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
