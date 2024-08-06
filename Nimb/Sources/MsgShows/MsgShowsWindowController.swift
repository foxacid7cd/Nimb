// SPDX-License-Identifier: MIT

import AppKit

class MsgShowsWindowController: NSWindowController {
  init(store: Store) {
    self.store = store

    let viewController = MsgShowsViewController(store: store)
    let window = NSWindow(contentViewController: viewController)
    window.styleMask = [.resizable, .titled]
    window.isMovable = true
    window.animationBehavior = .utilityWindow
    window.title = "Messages"
    super.init(window: window)

    self.viewController = viewController

    window.setIsVisible(true)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func render(_ stateUpdates: State.Updates) {
    if stateUpdates.isMessagesUpdated || stateUpdates.isAppearanceUpdated {
      if !store.state.msgShows.isEmpty {
//        renderContent()
      }
    }

    if stateUpdates.isMessagesUpdated {
      let show = !store.state.msgShows.isEmpty && !store.state.isMsgShowsDismissed
      if show {
        window!.orderFront(nil)
      }
    }

    viewController.render(stateUpdates)
  }

  private let store: Store
  private var viewController: MsgShowsViewController!
}
