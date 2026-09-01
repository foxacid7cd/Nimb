// SPDX-License-Identifier: MIT

import AppKit
import CustomDump
import NimbCore
import NimbNeovim
import NimbState
import Synchronization

public class AppDelegate: NSObject, NSApplicationDelegate, Rendering {
  public var renderContext: RenderContext! = nil

  private var mainMenuController: MainMenuController? = nil
  private var mainWindowController: MainWindowController? = nil
  private var settingsWindowController: SettingsWindowController? = nil
  private var keyDownMonitor: Any? = nil

  private var neovim: Neovim? = nil
  private var store: Store? = nil
  private var alertsTask: Task<Void, Never>? = nil
  private var updatesTask: Task<Void, Never>? = nil

  private nonisolated let pendingStateAndUpdates = Mutex<(State, State.Updates)?>(nil)

  private var appliedGuifont: String? = nil

  /// Files handed over by Launch Services, held until Neovim is attached: the
  /// first ones arrive before the process has even been spawned.
  private var pendingOpenURLs = [URL]()
  private var isNeovimAttached = false

  private var cursorBlinkTask: Task<Void, Never>? = nil

  override public init() {
    super.init()
  }

  public func render() {
    renderChildren(mainMenuController!, mainWindowController!)
  }

  public func applicationDidFinishLaunching(_: Notification) {
    let initialState = State(
      debug: UserDefaults.standard.debug,
      font: .init(),
    )

    // Applied here rather than from isDebugUpdated, which never carries it: the
    // flag is restored into the initial state rather than toggled into it.
    renderStats.isEnabled = initialState.debug.isFrameStatsLoggingEnabled

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

      // `:restart` exits the old server on purpose, having handed over a
      // replacement to attach to, so this exit is not the app's to act on.
      guard !neovim.isReattaching.withLock({ $0 }) else {
        return
      }
      NSApplication.shared.terminate(nil)
    }

    logger.debug("Application did finish launching")
  }

  public func application(_: NSApplication, open urls: [URL]) {
    pendingOpenURLs.append(contentsOf: urls)
    openPendingURLs()
  }

  /// Quitting from the Dock, the Apple menu or a logout never reaches the menu
  /// handler. Neovim is asked to quit instead, and terminating is left to the
  /// process exiting, so a cancelled prompt leaves everything running.
  public func applicationShouldTerminate(
    _: NSApplication,
  )
    -> NSApplication.TerminateReply
  {
    guard let store, isNeovimAttached else {
      return .terminateNow
    }
    store.api.nimbFast(method: "quit_all")
    return .terminateCancel
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

  private func openPendingURLs() {
    guard isNeovimAttached, !pendingOpenURLs.isEmpty, let store else {
      return
    }
    let paths = pendingOpenURLs.map { Value.string($0.path(percentEncoded: false)) }
    pendingOpenURLs.removeAll()

    store.api.nimbFast(method: "open_paths", parameters: [.array(paths)])
  }

  private func restartCursorBlinking(state: State) {
    cursorBlinkTask?.cancel()
    cursorBlinkTask = nil

    let style = state.currentCursorStyle
    guard
      let blinkWait = style?.blinkWait, blinkWait > 0,
      let blinkOn = style?.blinkOn, blinkOn > 0,
      let blinkOff = style?.blinkOff, blinkOff > 0
    else {
      // Any of the three at zero turns blinking off, so the cursor stays on.
      if !state.cursorBlinkingPhase {
        store?.dispatch(Actions.SetCursorBlinkingPhase(value: true))
      }
      return
    }

    if !state.cursorBlinkingPhase {
      store?.dispatch(Actions.SetCursorBlinkingPhase(value: true))
    }
    cursorBlinkTask = Task { @MainActor [weak self] in
      do {
        try await Task.sleep(for: .milliseconds(blinkWait))
        while true {
          self?.store?.dispatch(Actions.SetCursorBlinkingPhase(value: false))
          try await Task.sleep(for: .milliseconds(blinkOff))
          self?.store?.dispatch(Actions.SetCursorBlinkingPhase(value: true))
          try await Task.sleep(for: .milliseconds(blinkOn))
        }
      } catch {
        // Cancelled by the next restart, which shows the cursor itself.
      }
    }
  }

  private func applyGuifontIfNeeded(state: State) {
    guard
      case let .string(guifont)? = state.rawOptions["guifont"],
      guifont != appliedGuifont
    else {
      return
    }
    appliedGuifont = guifont

    let resolved = Font.parseGuifont(guifont)
      .lazy
      .compactMap { entry in
        NSFont(name: entry.name, size: entry.size ?? state.font.appKit().pointSize)
      }
      .first
    guard let resolved else {
      return
    }
    store?.dispatch(Actions.SetFont(value: Font(resolved)))
  }

  /// Called from the main actor already, so it renders inline rather than in a
  /// task that could paint out of order with the next frame's.
  private func render(state: State, updates: State.Updates) {
    if !isNeovimAttached {
      // Updates only start once the UI is attached, so the first one is the
      // signal that API calls will be answered.
      isNeovimAttached = true
      openPendingURLs()
    }
    if updates.isRawOptionsUpdated {
      applyGuifontIfNeeded(state: state)
    }
    // Both restart the cycle: a moved cursor waits out blinkwait again, and a
    // mode change may have brought a different set of timings with it.
    if updates.isCursorUpdated || updates.isModeUpdated {
      restartCursorBlinking(state: state)
    }
    if updates.isPendingReattachUpdated, let address = state.pendingReattachAddress {
      reattach(to: address)
    }
    if updates.isAppearanceUpdated {
      renderStats.count(.appearanceUpdatedFrames)
    }
    measuringRenderStage("frame hop", .frameHop) {
      update(renderContext: .init(state: state, updates: updates))
      render()
    }
    renderStats.frameCompleted()
  }

  private func reattach(to address: String) {
    guard let neovim, let store else {
      return
    }
    Task {
      do {
        try await neovim.reattach(to: address)
        store.dispatch(Actions.ResetState(initialState: State(
          debug: UserDefaults.standard.debug,
          font: .init(),
        )))
      } catch {
        await show(alert: .init(error))
      }
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

  /// Explicitly off the main actor, which a bare `Task` would inherit from the
  /// app target's default. The hop back happens once per coalesced frame.
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
            if updates.isDebugUpdated {
              UserDefaults.standard.debug = state.debug
              renderStats.isEnabled = state.debug.isFrameStatsLoggingEnabled
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
