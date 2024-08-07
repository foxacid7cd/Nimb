// SPDX-License-Identifier: MIT

import AppKit
import CustomDump

@MainActor
public class AppDelegate: NSObject, NSApplicationDelegate {
  override public nonisolated init() {
    super.init()
  }

  public func applicationDidFinishLaunching(_: Notification) {
    Task {
      await setupStore()
      setupMainMenuController()
      setupMsgShowsWindowController()
      showMainWindowController()
      runStateUpdatesTask()

      do {
        try await instance!.run()
      } catch {
        showAlert(error: error)
      }
    }
  }

  public func applicationWillTerminate(_: Notification) {
    stateUpdatesTask?.cancel()
    neovimAlertMessagesTask?.cancel()
  }

  private var instance: Instance?
  private var store: Store?
  private var neovimAlertMessagesTask: Task<Void, Never>?
  private var stateUpdatesTask: Task<Void, Never>?
  private var mainMenuController: MainMenuController?
  private var msgShowsWindowController: MsgShowsWindowController?
  private var mainWindowController: MainWindowController?
  private var settingsWindowController: SettingsWindowController?

  private func setupStore() async {
    let debugState = UserDefaults.standard.debug
    instance = Instance(
      nvimResourcesURL: Bundle.main.resourceURL!.appending(path: "nvim"),
      initialOuterGridSize: UserDefaults.standard.outerGridSize,
      isMessagePackInspectorEnabled: debugState.isMessagePackInspectorEnabled
    )
    store = .init(
      instance: instance!,
      debug: debugState,
      font: UserDefaults.standard.appKitFont.map(Font.init) ?? .init()
    )
    neovimAlertMessagesTask = Task {
      for await message in store!.neovimAlertMessages {
        showAlert(message: message)
      }
    }
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

  private func setupMsgShowsWindowController() {
    msgShowsWindowController = MsgShowsWindowController(store: store!)
  }

  private func runStateUpdatesTask() {
    stateUpdatesTask = Task { [weak self] in
      await withUnsafeContinuation { continuation in
        Task {
          let store = self!.store!
          let mainWindowController = self!.mainWindowController!
          let msgShowsWindowController = self!.msgShowsWindowController!

          do {
            var presentedNimbNotifiesCount = 0

            for try await stateUpdates in store {
              guard !Task.isCancelled else {
                return
              }

              if stateUpdates.isOuterGridLayoutUpdated {
                UserDefaults.standard.outerGridSize = store.state.outerGrid!
                  .size
              }
              if stateUpdates.isFontUpdated {
                UserDefaults.standard.appKitFont = store.state.font.appKit()
              }
              if stateUpdates.isDebugUpdated {
                UserDefaults.standard.debug = store.state.debug
              }
              if stateUpdates.isNimbNotifiesUpdated {
                for _ in presentedNimbNotifiesCount ..< store.state.nimbNotifies.count {
                  let notification = store.state.nimbNotifies[presentedNimbNotifiesCount]

                  let process = Process()
                  process.executableURL = URL(filePath: "/usr/bin/osascript")
                  process.arguments = [
                    "-e",
                    """
                    display notification "\(notification.message)" with title "\(notification.title ?? "Nimb")"
                    """,
                  ]
                  process.environment = ProcessInfo.processInfo.environment
                  try process.run()
                }
                presentedNimbNotifiesCount = store.state.nimbNotifies.count
              }

              mainWindowController.render(stateUpdates)
              msgShowsWindowController.render(stateUpdates)
            }

            continuation.resume(returning: ())
          } catch {
            self?.showAlert(error: error)
          }
        }
      }

      NSApplication.shared.terminate(nil)
    }
  }

  private func showAlert(error: Error) {
    let alert = NSAlert()
    alert.alertStyle = .critical
    alert.messageText = "Something went wrong!"
    alert
      .informativeText =
      "Store state updates loop ended with uncaught error"
    alert.addButton(withTitle: "Show log")
    alert.addButton(withTitle: "Close")
    alert
      .beginSheetModal(
        for: mainWindowController!.window!
      ) { response in
        switch response {
        case .alertFirstButtonReturn:
          let temporaryDirectoryURL = URL(
            fileURLWithPath: NSTemporaryDirectory(),
            isDirectory: true
          )
          let logFileName =
            "Nimb-error-log-\(ProcessInfo().globallyUniqueString).txt"
          let temporaryFileURL = temporaryDirectoryURL
            .appending(component: logFileName)

          var errorLog = ""
          customDump(error, to: &errorLog)

          try! errorLog.data(using: .utf8)!.write(
            to: temporaryFileURL,
            options: []
          )
          NSWorkspace.shared.open(temporaryFileURL)

        default:
          break
        }
      }
  }

  private func showAlert(message: String) {
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = message
    alert.addButton(withTitle: "Close")
    alert.beginSheetModal(for: mainWindowController!.window!)
  }
}
