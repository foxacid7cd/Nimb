// SPDX-License-Identifier: MIT

import AppKit
import CustomDump

@MainActor
public class AppDelegate: NSObject, NSApplicationDelegate, Rendering {
  private var neovim: Neovim?
  private var store: Store?

  private var mainMenuController: MainMenuController?
  private var msgShowsWindowController: MsgShowsWindowController?
  private var mainWindowController: MainWindowController?
  private var settingsWindowController: SettingsWindowController?

  private var alertsTask: Task<Void, Never>?
  @StateActor private var updatesTask: Task<Void, Never>?

  override public init() {
    super.init()
  }

  public func render() {
    renderChildren(mainMenuController!, msgShowsWindowController!, mainWindowController!)
  }

  public func applicationDidFinishLaunching(_: Notification) {
    Task {
      neovim = .init()
      store = .init(api: neovim!.api)
      setupInitialControllers()
      alertsTask = Task {
        do {
          for await alert in store!.alerts {
            try Task.checkCancellation()

            show(alert: alert)
          }
        } catch { }
      }
      await setupUpdatesBinding()

      do {
        try await neovim!.bootstrap()

        _ = await NotificationCenter.default
          .notifications(
            named: Process.didTerminateNotification,
            object: neovim!.process
          )
          .makeAsyncIterator()
          .next()
        let status = neovim!.process.terminationStatus
        let reason = neovim!.process.terminationReason.rawValue
        logger.debug("Neovim process terminated with status \(status) and reason \(reason)")
      } catch {
        logger.error("Neovim process boostrap error: \(String(customDumping: error))")
        await showCriticalAlert(error: error)
      }

      NSApplication.shared.terminate(nil)
    }

    logger.debug("Application did finish launching")
  }

  public func applicationWillTerminate(_: Notification) {
    logger.debug("Application will terminate")
  }

  public func applicationDidBecomeActive(_: Notification) {
    store!.dispatch(Actions.SetApplicationActive(value: true))
  }

  public func applicationWillResignActive(_: Notification) {
    store!.dispatch(Actions.SetApplicationActive(value: false))
  }

  @StateActor
  private func setupUpdatesBinding() {
    updatesTask = Task {
      do {
        var presentedNimbNotifiesCount = 0

        for await (state, updates) in await self.store!.updates {
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
              Task { @MainActor in
                self.showNimbNotify(notification)
              }
            }
            presentedNimbNotifiesCount = state.nimbNotifies.count
          }

          Task { @MainActor in
            self.update(renderContext: .init(state: state, updates: updates))
            self.render()
          }
        }
        await logger.debug("Store state updates loop ended")
      } catch is CancellationError {
        await logger.debug("Store state updates loop cancelled")
      } catch {
        await logger.error("Store state updates loop error: \(error)")
//        await self.showCriticalAlert(error: error)
      }
    }
  }

  @MainActor
  private func setupInitialControllers() {
    mainMenuController = MainMenuController(store: store!)
    mainMenuController!.settingsClicked = { [unowned self] in
      if settingsWindowController == nil {
        settingsWindowController = .init(store: store!)
        renderChildren(settingsWindowController!)
      }
      settingsWindowController!.showWindow(nil)
    }
    NSApplication.shared.mainMenu = mainMenuController!.menu

    mainWindowController = MainWindowController(
      store: store!,
      minOuterGridSize: .init(columnsCount: 80, rowsCount: 24)
    )

    msgShowsWindowController = MsgShowsWindowController(store: store!)
  }

  @MainActor
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

  @MainActor
  private func show(alert: Alert) {
    let appKitAlert = NSAlert()
    appKitAlert.alertStyle = .warning
    appKitAlert.messageText = alert.message
    appKitAlert.addButton(withTitle: "Close")
    appKitAlert.beginSheetModal(for: mainWindowController!.window!)
  }

  @MainActor
  private func showNimbNotify(_ notify: NimbNotify) {
    logger.debug("AppDelegate.showNimbNotify: \(String(customDumping: notify))")

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
