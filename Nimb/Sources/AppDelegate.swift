// SPDX-License-Identifier: MIT

import AppKit
import CustomDump

@MainActor
public class AppDelegate: NSObject, NSApplicationDelegate, Rendering {
  override public init() {
    super.init()
  }

  public func render() {
    renderChildren(mainMenuController!, msgShowsWindowController!, mainWindowController!)
  }

  public func applicationDidFinishLaunching(_: Notification) {
    Task {
      await setupStore()
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

  private func setupStore() async {
    let debugState = UserDefaults.standard.debug
    instance = Instance(
      nvimResourcesURL: Bundle.main.resourceURL!.appending(path: "nvim"),
      initialOuterGridSize: UserDefaults.standard.outerGridSize,
      isMessagePackInspectorEnabled: debugState.isMessagePackInspectorEnabled
    )
    store = await .init(
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
    updatesTask = .init(priority: .userInitiated) {
      do {
        var presentedNimbNotifiesCount = 0

        NSApplication.shared.terminate(nil)
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
