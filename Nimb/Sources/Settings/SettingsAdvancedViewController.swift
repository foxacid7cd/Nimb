// SPDX-License-Identifier: MIT

import AppKit
import NimbState

final class SettingsAdvancedViewController: NSViewController, Rendering {
  var renderContext: RenderContext! = nil

  private let store: Store
  private lazy var uiEvents = checkbox("Log Neovim UI events", action: #selector(toggleUIEvents))
  private lazy var messagePack = checkbox("Capture MessagePack traffic", action: #selector(toggleMessagePack))
  private lazy var storeActions = checkbox("Log state actions", action: #selector(toggleStoreActions))
  private lazy var frameStats = checkbox("Log rendering performance", action: #selector(toggleFrameStats))
  private lazy var reduceOnMain = checkbox("Reduce state on main thread", action: #selector(toggleReduceOnMain))

  init(store: Store) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    let view = NSView(frame: .init(x: 0, y: 0, width: 520, height: 350))
    let note = NSTextField(wrappingLabelWithString: "These options are intended for diagnostics. Reducing state on the main thread takes effect after restarting Nimb.")
    note.textColor = .secondaryLabelColor

    let stack = NSStackView(views: [
      uiEvents,
      messagePack,
      storeActions,
      frameStats,
      reduceOnMain,
      note,
    ])
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = 12
    stack.setCustomSpacing(20, after: reduceOnMain)
    view.addSubview(stack)
    stack.edgesToSuperview(insets: .init(top: 24, left: 24, bottom: 24, right: 24))
    note.width(to: stack)
    self.view = view
  }

  func render() {
    uiEvents.state = state.debug.isUIEventsLoggingEnabled ? .on : .off
    messagePack.state = state.debug.isMessagePackInspectorEnabled ? .on : .off
    storeActions.state = state.debug.isStoreActionsLoggingEnabled ? .on : .off
    frameStats.state = state.debug.isFrameStatsLoggingEnabled ? .on : .off
    reduceOnMain.state = state.debug.isReducingOnMainThreadEnabled ? .on : .off
  }

  private func checkbox(_ title: String, action: Selector) -> NSButton {
    NSButton(checkboxWithTitle: title, target: self, action: action)
  }

  @objc private func toggleUIEvents() {
    store.dispatch(Actions.ToggleDebugUIEventsLogging())
  }

  @objc private func toggleMessagePack() {
    store.dispatch(Actions.ToggleDebugMessagePackInspector())
  }

  @objc private func toggleStoreActions() {
    store.dispatch(Actions.ToggleStoreActionsLogging())
  }

  @objc private func toggleFrameStats() {
    store.dispatch(Actions.ToggleFrameStatsLogging())
  }

  @objc private func toggleReduceOnMain() {
    store.dispatch(Actions.ToggleReducingOnMainThread())
  }
}
