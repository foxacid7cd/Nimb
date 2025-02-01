// SPDX-License-Identifier: MIT

import AppKit
import CustomDump
import Queue

@MainActor
public class AppDelegate: NSObject, NSApplicationDelegate, Rendering {
  private var mainMenuController: MainMenuController?
  private var msgShowsWindowController: MsgShowsWindowController?
  private var mainWindowController: MainWindowController?
  private var settingsWindowController: SettingsWindowController?

  private var neovim: Neovim?
  private var store: Store?
  @StateActor private var alertsTask: Task<Void, Never>?
  @StateActor private var updatesTask: Task<Void, Never>?
  @StateActor private var renderQueue = AsyncQueue()

  override public nonisolated init() {
    super.init()
  }

  public func render() {
    renderChildren(mainMenuController!, msgShowsWindowController!, mainWindowController!)
  }

  public func applicationDidFinishLaunching(_: Notification) {
    let initialState = State(
      debug: UserDefaults.standard.debug,
      font: UserDefaults.standard.appKitFont.map(Font.init) ?? .init()
    )

    let neovim = Neovim()
    self.neovim = neovim

    let store = Store(api: neovim.api, initialState: initialState)
    self.store = store

    setupInitialControllers(store: store)

    Task { @StateActor in
      setupBindings(store: store)

      let terminationStatus = await neovim.bootstrap()
      logger.debug("Neovim process terminated with status \(terminationStatus)")

      await NSApplication.shared.terminate(nil)
    }

    logger.debug("Application did finish launching")
  }

  public func applicationWillTerminate(_: Notification) {
    logger.debug("Application will terminate")
  }

  public func applicationDidBecomeActive(_: Notification) {
    store?.dispatch(Actions.SetApplicationActive(value: true))
  }

  public func applicationWillResignActive(_: Notification) {
    store?.dispatch(Actions.SetApplicationActive(value: false))
  }

  @MainActor
  public func render(state: State, updates: State.Updates) {
    update(renderContext: .init(state: state, updates: updates))
    render()
  }

  @StateActor
  private func setupBindings(store: Store) {
    alertsTask = Task {
      do {
        for await alert in store.alerts {
          try Task.checkCancellation()

          await show(alert: alert)
        }
      } catch { }
    }
    updatesTask = Task {
      do {
        var presentedNimbNotifiesCount = 0

        for await (state, updates) in store.updates {
          try Task.checkCancellation()

          if updates.isNimbNotifiesUpdated {
            for _ in presentedNimbNotifiesCount ..< state.nimbNotifies.count {
              let notification = state.nimbNotifies[presentedNimbNotifiesCount]
              await self.showNimbNotify(notification)
            }
            presentedNimbNotifiesCount = state.nimbNotifies.count
          }

          renderQueue.addOperation { @MainActor [state, updates] in
            guard !Task.isCancelled else {
              return
            }
            if updates.isOuterGridLayoutUpdated, let outerGrid = state.outerGrid {
              UserDefaults.standard.outerGridSize = outerGrid.size
            }
            if updates.isFontUpdated {
              UserDefaults.standard.appKitFont = state.font.appKit()
            }
            if updates.isDebugUpdated {
              UserDefaults.standard.debug = state.debug
            }
            if updates.isErrorExitStatusUpdated {
              logger.error("Neovim process emitted erorr exit UI event with status \(state.errorExitStatus ?? 0)")
            }
            self.render(state: state, updates: updates)
          }
        }
        logger.debug("Store state updates loop ended")
      } catch is CancellationError {
        logger.debug("Store state updates loop cancelled")
      } catch {
        logger.error("Store state updates loop error: \(error)")
        await self.showCriticalAlert(error: error)
      }
    }
  }

  private func setupInitialControllers(store: Store) {
    mainMenuController = MainMenuController(store: store)
    mainMenuController!.settingsClicked = { [unowned self] in
      if settingsWindowController == nil {
        settingsWindowController = .init(store: store)
        renderChildren(settingsWindowController!)
      }
      settingsWindowController!.showWindow(nil)
    }
    NSApplication.shared.mainMenu = mainMenuController!.menu

    mainWindowController = MainWindowController(
      store: store,
      minOuterGridSize: .init(columnsCount: 80, rowsCount: 24)
    )

    msgShowsWindowController = MsgShowsWindowController(store: store)
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

  private func show(alert: Alert) {
    let appKitAlert = NSAlert()
    appKitAlert.alertStyle = .warning
    appKitAlert.messageText = alert.message
    appKitAlert.addButton(withTitle: "Close")
    appKitAlert.beginSheetModal(for: mainWindowController!.window!)
  }

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
