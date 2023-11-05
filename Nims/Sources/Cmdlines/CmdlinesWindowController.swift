// SPDX-License-Identifier: MIT

import IdentifiedCollections
import Library
import SwiftUI
import TinyConstraints

public final class CmdlinesWindowController: NSWindowController, NSWindowDelegate {
  public init(store: Store, parentWindow: NSWindow) {
    self.store = store
    self.parentWindow = parentWindow

    viewController = CmdlinesViewController(store: store)

    let window = NimsNSWindow(contentViewController: viewController)
    window._canBecomeKey = false
    window._canBecomeMain = false
    window.styleMask = [.titled, .fullSizeContentView]
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.isMovable = false
    window.isOpaque = false
    window.setIsVisible(false)

    super.init(window: window)

    window.delegate = self

    updateWindow()
  }

  deinit {
    task?.cancel()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func render(_ stateUpdates: State.Updates) {
    if stateUpdates.isCursorBlinkingPhaseUpdated || stateUpdates.isBusyUpdated || stateUpdates.isCmdlinesUpdated || stateUpdates.isAppearanceUpdated || stateUpdates.isFontUpdated {
      updateWindow()
    }
  }

  public func point(forCharacterLocation location: Int) -> CGPoint? {
    viewController.point(forCharacterLocation: location)
      .map { window!.convertPoint(toScreen: $0) }
  }

  public func windowDidResize(_: Notification) {
    window!.setFrameOrigin(.init(
      x: parentWindow.frame.origin.x + (parentWindow.frame.width - window!.frame.width) / 2,
      y: parentWindow.frame.origin.y + parentWindow.frame.height / 1.5
    ))
  }

  private let store: Store
  private let parentWindow: NSWindow
  private let viewController: CmdlinesViewController
  private var task: Task<Void, Never>?

  private func updateWindow() {
    guard let window else {
      return
    }

    viewController.reloadData()

    let cmdlines = store.state.cmdlines
    if cmdlines.dictionary.isEmpty {
      parentWindow.removeChildWindow(window)
      window.setIsVisible(false)

    } else {
      parentWindow.addChildWindow(window, ordered: .above)
    }
  }
}
