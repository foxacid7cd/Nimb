// SPDX-License-Identifier: MIT

import AppKit

class MsgShowsWindowController: NSWindowController, Rendering {
  private class CustomWindow: NSPanel {
    override var canBecomeMain: Bool {
      false
    }

    override var canBecomeKey: Bool {
      true
    }

    var keyPressed: ((KeyPress) -> Void)?

    override func keyDown(with event: NSEvent) {
      keyPressed?(.init(event: event))
    }
  }

  private let store: Store
  private var viewController: MsgShowsViewController!
  private var customWindow: CustomWindow!
  private var isWindowInitiallyShown = false

  init(store: Store) {
    self.store = store

    let viewController = MsgShowsViewController(store: store)
    let window = CustomWindow(contentViewController: viewController)
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
    window.keyPressed = { keyPress in
      do {
        try store.api.keyPressed(keyPress)
      } catch {
        store.show(alert: .init(error))
      }
    }
    super.init(window: window)

    window.delegate = self
    self.viewController = viewController
    customWindow = window
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func render() {
    renderChildren(viewController)

    if !updates.msgShowsUpdates.isEmpty {
      if !state.msgShows.isEmpty {
        if !isWindowInitiallyShown, let frame = UserDefaults.standard.lastMsgShowsWindowFrame {
          customWindow!.setFrame(frame, display: false, animate: false)
          isWindowInitiallyShown = true
        }
        customWindow!.isFloatingPanel = state.hasModalMsgShows
        customWindow!.setIsVisible(true)
        customWindow!.orderFrontRegardless()
      } else {
        customWindow!.setIsVisible(false)
      }
    }
  }

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
