// SPDX-License-Identifier: MIT

import AppKit

class MsgShowsWindowController: NSWindowController {
  init(store: Store) {
    self.store = store

    let viewController = MsgShowsViewController(store: store)
    let window = CustomWindow(contentViewController: viewController)
    window.keyPressed = { keyPress in
      store.report(keyPress: keyPress)
    }
    window.styleMask = [.titled, .resizable]
    window.titlebarAppearsTransparent = false
    window.isOpaque = false
    window.isMovable = true
    window.isMovableByWindowBackground = true
    window.title = "Messages"
    window.setAnchorAttribute(.bottom, for: .vertical)
    window.setAnchorAttribute(.left, for: .horizontal)
    window.hasShadow = true
    window.alphaValue = 0.9
    super.init(window: window)

    window.delegate = self
    self.viewController = viewController
    customWindow = window
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func render(_ stateUpdates: State.Updates) {
    viewController.render(stateUpdates)

    if !stateUpdates.msgShowsUpdates.isEmpty {
      if !store.state.msgShows.isEmpty {
        if !isWindowInitiallyShown, let frame = UserDefaults.standard.lastMsgShowsWindowFrame {
          customWindow!.setFrame(frame, display: false, animate: false)
          isWindowInitiallyShown = true
        }
        customWindow!.isFloatingPanel = store.state.hasModalMsgShows
        customWindow!.setIsVisible(true)
        customWindow!.orderFrontRegardless()
      } else {
        customWindow!.setIsVisible(false)
      }
    }
  }

  private class CustomWindow: NSPanel {
    var keyPressed: ((KeyPress) -> Void)?

    override var canBecomeMain: Bool {
      false
    }

    override var canBecomeKey: Bool {
      true
    }

    override func keyDown(with event: NSEvent) {
      keyPressed?(.init(event: event))
    }
  }

  private let store: Store
  private var viewController: MsgShowsViewController!
  private var customWindow: CustomWindow!
  private var isWindowInitiallyShown = false

  private func saveWindowFrame() {
    UserDefaults.standard.lastMsgShowsWindowFrame = customWindow.frame
  }
}

extension MsgShowsWindowController: NSWindowDelegate {
  func windowDidResize(_: Notification) {
    if !customWindow.inLiveResize {
      saveWindowFrame()
    }
  }

  func windowDidMove(_: Notification) {
    saveWindowFrame()
  }

  func windowDidEndLiveResize(_: Notification) {
    saveWindowFrame()
  }
}
