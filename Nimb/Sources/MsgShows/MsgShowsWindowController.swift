// SPDX-License-Identifier: MIT

import AppKit

class MsgShowsWindowController: NSWindowController {
  init(store: Store) {
    self.store = store

    let viewController = MsgShowsViewController(store: store)
    let window = NSPanel(contentViewController: viewController)
    window.styleMask = [.resizable, .borderless]
    window.isOpaque = false
    window.isMovable = true
    window.isFloatingPanel = true
    window.allowsConcurrentViewDrawing = true
    window.isMovableByWindowBackground = true
    window.level = .floating
    window.setAnchorAttribute(.bottom, for: .vertical)
    window.setAnchorAttribute(.left, for: .horizontal)
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
        if !isWindowInitiallyShown {
          window!.setIsVisible(true)
        }
        window!.orderFront(nil)
      }
    }
  }

  private let store: Store
  private var viewController: MsgShowsViewController!
  private var isWindowInitiallyShown = false
}
