// SPDX-License-Identifier: MIT

import AppKit
import CustomDump

@MainActor
public class AppDelegate: NSObject, NSApplicationDelegate {
  override public init() {
    super.init()
  }

  public func applicationDidFinishLaunching(_: Notification) {
    Task {
      setupStore()
      setupMainMenuController()
      setupMsgShowsWindowController()
      setupMainWindowController()
      do {
        try await instance!.run()
      } catch {
        await showCriticalAlert(error: error)
        NSApplication.shared.terminate(nil)
      }
      logger.debug("NSApplication did finish launching")
    }
  }

  public func applicationWillTerminate(_: Notification) {
    logger.debug("NSApplication will terminate")
    updatesTask?.cancel()
    alertMessagesTask?.cancel()
  }

  private var instance: Instance?
  private var store: Store?

  private var mainMenuController: MainMenuController?
  private var msgShowsWindowController: MsgShowsWindowController?
  private var mainWindowController: MainWindowController?
  private var settingsWindowController: SettingsWindowController?

  private var alertMessagesTask: Task<Void, Never>?
  private var updatesTask: Task<Void, Never>?

  private func setupStore() {
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
    alertMessagesTask = Task {
      do {
        for await message in store!.alertMessages {
          try Task.checkCancellation()
          showAlert(message)
        }
      } catch { }
    }
    updatesTask = Task {
      do {
        var presentedNimbNotifiesCount = 0
        for try await (state, updates) in store!.updates {
          try Task.checkCancellation()

          if updates.isOuterGridLayoutUpdated {
            UserDefaults.standard.outerGridSize = state.outerGrid!.size
          }
          if updates.isFontUpdated {
            UserDefaults.standard.appKitFont = state.font.appKit()
          }
          if updates.isDebugUpdated {
            UserDefaults.standard.debug = state.debug
          }
          if updates.isNimbNotifiesUpdated {
            for _ in presentedNimbNotifiesCount ..< state.nimbNotifies.count {
              let notification = state.nimbNotifies[presentedNimbNotifiesCount]
              showNimbNotify(notification)
            }
            presentedNimbNotifiesCount = state.nimbNotifies.count
          }

          store!._state = state
          store!._updates = updates

          self.update(renderContext: .init(state: state, updates: updates))
          self.render()
        }
        logger.debug("Store state updates loop ended")
      } catch is CancellationError {
        logger.debug("Store state updates loop cancelled")
      } catch {
        logger.error("Store state updates loop error: \(error)")
        await self.showCriticalAlert(error: error)
      }

      NSApplication.shared.terminate(nil)
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

  private func setupMainWindowController() {
    mainWindowController = MainWindowController(
      store: store!,
      minOuterGridSize: .init(columnsCount: 80, rowsCount: 24)
    )
  }

  private func setupMsgShowsWindowController() {
    msgShowsWindowController = MsgShowsWindowController(store: store!)
  }

  private func showCriticalAlert(error: Error) async {
    let alert = NSAlert()
    alert.alertStyle = .critical
    alert.messageText = "Something went wrong!"
    alert.informativeText = "Store state updates loop ended with uncaught error"
    alert.addButton(withTitle: "Details")
    alert.addButton(withTitle: "Close")
    await withUnsafeContinuation { continuation in
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

            try! String(customDumping: error).data(using: .utf8)!.write(
              to: temporaryFileURL,
              options: []
            )
            NSWorkspace.shared.open(temporaryFileURL)

          default:
            break
          }

          continuation.resume(returning: ())
        }
    }
  }

  private func showAlert(_ message: AlertMessage) {
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = message.content
    alert.addButton(withTitle: "Close")
    alert.beginSheetModal(for: mainWindowController!.window!)
  }

  private func showNimbNotify(_ notify: NimbNotify) {
    let process = Process()
    process.executableURL = URL(filePath: "/usr/bin/osascript")
    process.arguments = [
      "-e",
      "display notification \"\(notify.message)\" with title \"\(notify.title ?? "Nimb")\"",
    ]
    process.environment = ProcessInfo.processInfo.environment
    do {
      try process.run()
    } catch {
      logger.error("Failed to run /usr/bin/osascript: \(error)")
    }
  }
}

extension AppDelegate: Rendering {
  public func render() {
    renderChildren(mainWindowController!, msgShowsWindowController!, mainMenuController!)
  }
}
