// SPDX-License-Identifier: MIT

import AppKit
import CustomDump
import Library

@MainActor
public class AppDelegate: NSObject, NSApplicationDelegate {
  override public nonisolated init() {
    super.init()
  }

  public func applicationDidFinishLaunching(_: Notification) {
    Task {
      await setupStore()
      setupMainMenuController()
      showMainWindowController()
      runStateUpdatesTask()

      do {
        try await instance!.run()
      } catch {
        customDump(error)
        assertionFailure()
      }
    }
  }

  private var instance: Instance?
  private var store: Store?
  private var stateUpdatesTask: Task<Void, Never>?
  private var mainMenuController: MainMenuController?
  private var mainWindowController: MainWindowController?
  private var settingsWindowController: SettingsWindowController?

  private func setupStore() async {
    instance = Instance(
      nvimResourcesURL: Bundle.main.resourceURL!.appending(path: "nvim"),
      initialOuterGridSize: UserDefaults.standard.outerGridSize
    )
    store = .init(
      instance: instance!,
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
    stateUpdatesTask = Task { [weak self] in
      await withUnsafeContinuation { continuation in
        Task {
          let store = self!.store!
          let mainWindowController = self!.mainWindowController!

          do {
            for try await stateUpdates in store {
              guard !Task.isCancelled else {
                return
              }

              if stateUpdates.isOuterGridLayoutUpdated {
                UserDefaults.standard.outerGridSize = store.state.outerGrid!.size
              }
              if stateUpdates.isFontUpdated {
                UserDefaults.standard.appKitFont = store.state.font.appKit()
              }
              if stateUpdates.isDebugUpdated {
                UserDefaults.standard.debug = store.state.debug
              }

              CATransaction.begin()
              CATransaction.setDisableActions(true)
              mainWindowController.render(stateUpdates)
              CATransaction.commit()
            }

            continuation.resume(returning: ())
          } catch {
            var errorLog = ""
            customDump(error, to: &errorLog)
            logger.error("Store state updates loop resulted in error: \(errorLog))")

            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "Something went wrong!"
            alert.informativeText = "Store state updates loop ended with uncaught error"
            alert.addButton(withTitle: "Show log")
            alert.addButton(withTitle: "Close")
            alert.beginSheetModal(for: self!.mainWindowController!.window!) { response in
              switch response {
              case .alertFirstButtonReturn:
                let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                let logFileName = "Nimb-error-log-\(ProcessInfo().globallyUniqueString).txt"
                let temporaryFileURL = temporaryDirectoryURL.appending(component: logFileName)

                try! errorLog.data(using: .utf8)!.write(to: temporaryFileURL, options: .atomic)
                NSWorkspace.shared.open(temporaryFileURL)

              default:
                break
              }

              continuation.resume(returning: ())
            }
          }
        }
      }

      NSApplication.shared.terminate(nil)
    }
  }
}
