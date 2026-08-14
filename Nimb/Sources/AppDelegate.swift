// SPDX-License-Identifier: MIT

import AppKit
import CustomDump
import NimbCore
import NimbNeovim
import NimbState
import Synchronization

public class AppDelegate: NSObject, NSApplicationDelegate, Rendering {
  private var mainMenuController: MainMenuController? = nil
  private var msgShowsWindowController: MsgShowsWindowController? = nil
  private var mainWindowController: MainWindowController? = nil
  private var settingsWindowController: SettingsWindowController? = nil
  private var keyDownMonitor: Any? = nil

  private var neovim: Neovim? = nil
  private var store: Store? = nil
  private var alertsTask: Task<Void, Never>? = nil
  private var updatesTask: Task<Void, Never>? = nil

  private nonisolated let pendingStateAndUpdates = Mutex<(State, State.Updates)?>(nil)

  override public init() {
    super.init()
  }

  public func render() {
    renderChildren(mainMenuController!, msgShowsWindowController!, mainWindowController!)
  }

  public func applicationDidFinishLaunching(_: Notification) {
    let initialState = State(
      debug: UserDefaults.standard.debug,
      font: UserDefaults.standard.appKitFont.map(Font.init) ?? .init(),
    )

    let neovim = Neovim()
    self.neovim = neovim

    let store = Store(api: neovim.api, initialState: initialState)
    self.store = store

    setupInitialControllers(store: store)

    setupKeyDownMonitor(store: store)

    Task { @MainActor in
      setupBindings(store: store)

      let terminationStatus = await neovim.bootstrap()
      logger.debug("Neovim process terminated with status \(terminationStatus)")

      NSApplication.shared.terminate(nil)
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

  public nonisolated func render(state: State, updates: State.Updates) {
    Task { @MainActor in
      update(renderContext: .init(state: state, updates: updates))
      render()
    }
  }

  private func setupBindings(store: Store) {
    alertsTask = Task {
      do {
        for await alert in store.alerts {
          try Task.checkCancellation()

          await show(alert: alert)
        }
      } catch { }
    }
    updatesTask = Task { [weak self] in
      await self?.runUpdatesLoop(store: store)
    }
  }

  /// Explicitly off the main actor.
  ///
  /// The app target defaults to MainActor, and an unstructured Task started
  /// from a MainActor context inherits that isolation — so simply writing
  /// `Task { for await ... }` here would run the whole reducer-to-UI handoff
  /// on the main thread, serialising it against rendering. @concurrent forces
  /// this onto the cooperative pool regardless of who calls it. The hop to the
  /// main actor happens below, once per coalesced frame.
  @concurrent
  private nonisolated func runUpdatesLoop(store: Store) async {
    do {
      var presentedNimbNotifiesCount = 0

      for await (state, updates) in store.updates {
        try Task.checkCancellation()

        if updates.isNimbNotifiesUpdated {
          for _ in presentedNimbNotifiesCount ..< state.nimbNotifies.count {
            let notification = state.nimbNotifies[presentedNimbNotifiesCount]
            showNimbNotify(notification)
          }
          presentedNimbNotifiesCount = state.nimbNotifies.count
        }

        let shouldCreateRenderTask = pendingStateAndUpdates.withLock { value in
          defer {
            if var (_, updatesAccumulator) = value {
              updatesAccumulator.formUnion(updates)
              value = (state, updatesAccumulator)
            } else {
              value = (state, updates)
            }
          }
          return value == nil
        }

        if shouldCreateRenderTask {
          Task { @MainActor in
            let stateAndUpdates = pendingStateAndUpdates.withLock { value in
              defer { value = nil }
              return value
            }
            guard let (state, updates) = stateAndUpdates else {
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
      }
      logger.debug("Store state updates loop ended")
    } catch is CancellationError {
      logger.debug("Store state updates loop cancelled")
    } catch {
      logger.error("Store state updates loop error: \(error)")
      await showCriticalAlert(error: error)
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
      minOuterGridSize: .init(columnsCount: 80, rowsCount: 24),
    )

    msgShowsWindowController = MsgShowsWindowController(store: store)
  }

  private func setupKeyDownMonitor(store: Store) {
    keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
      if event.modifierFlags.contains(.command) {
        return event
      }
      store.api.keyPressed(.init(event: event))
      return nil
    }
  }

  private func showCriticalAlert(error: Error) async {
    let alert = NSAlert()
    alert.alertStyle = .critical
    alert.messageText = "Something went wrong!"
    alert.informativeText = "Store state updates loop ended with uncaught error"
    alert.addButton(withTitle: "Details")
    alert.addButton(withTitle: "Close")
    await withCheckedContinuation { continuation in
      alert
        .beginSheetModal(
          for: mainWindowController!.window!,
        ) { response in
          switch response {
          case .alertFirstButtonReturn:
            let temporaryDirectoryURL = URL(
              fileURLWithPath: NSTemporaryDirectory(),
              isDirectory: true,
            )
            let logFileName =
              "Nimb-error-log-\(ProcessInfo().globallyUniqueString).txt"
            let temporaryFileURL = temporaryDirectoryURL
              .appending(component: logFileName)

            try! String(customDumping: error).data(using: .utf8)!.write(
              to: temporaryFileURL,
              options: [],
            )
            NSWorkspace.shared.open(temporaryFileURL)

          default:
            break
          }

          continuation.resume(returning: ())
        }
    }
  }

  private func show(alert: Alert) async {
    let appKitAlert = NSAlert()
    appKitAlert.alertStyle = .warning
    appKitAlert.messageText = alert.message
    appKitAlert.addButton(withTitle: "Close")
    await appKitAlert.beginSheetModal(for: mainWindowController!.window!)
  }

  private nonisolated func showNimbNotify(_ notify: NimbNotify) {
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
