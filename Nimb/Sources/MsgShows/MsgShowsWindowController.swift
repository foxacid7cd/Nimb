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
    window.styleMask = [.titled, .resizable, .nonactivatingPanel]
    window.titlebarAppearsTransparent = false
    window.isOpaque = false
    window.isMovable = true
    window.isMovableByWindowBackground = true
    window.title = "Messages"
    window.setAnchorAttribute(.bottom, for: .vertical)
    window.setAnchorAttribute(.left, for: .horizontal)
    window.hasShadow = true
    super.init(window: window)

    self.viewController = viewController
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func render(_ stateUpdates: State.Updates) {
    if !stateUpdates.msgShowsUpdates.isEmpty || stateUpdates.isAppearanceUpdated {
      if !store.state.msgShows.isEmpty {
//        renderContent()
      }

      viewController.render(stateUpdates)
    }

    if !stateUpdates.msgShowsUpdates.isEmpty {
      let show = !store.state.msgShows.isEmpty && !store.state.isMsgShowsDismissed
      if show {
        window!.setIsVisible(true)
        window!.orderFront(nil)
      } else {
        window!.setIsVisible(false)
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
  private var isWindowInitiallyShown = false
}
