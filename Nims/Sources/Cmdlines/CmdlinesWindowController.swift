// SPDX-License-Identifier: MIT

import IdentifiedCollections
import Library
import Neovim
import SwiftUI
import TinyConstraints

final class CmdlinesWindowController: NSWindowController, NSWindowDelegate {
  private let store: Store
  private let parentWindow: NSWindow
  private let viewController: CmdlinesViewController
  private var task: Task<Void, Never>?

  init(store: Store, parentWindow: NSWindow) {
    self.store = store
    self.parentWindow = parentWindow

    viewController = CmdlinesViewController(store: store)

    let window = NSWindow(contentViewController: viewController)
    window.styleMask = [.titled, .fullSizeContentView]
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.isMovable = false
    window.isOpaque = false
    window.setIsVisible(false)

    super.init(window: window)

    window.delegate = self

    task = Task { [weak self] in
      for await stateUpdates in store.stateUpdatesStream() {
        guard let self, !Task.isCancelled else {
          break
        }

        if stateUpdates.isCmdlinesUpdated || stateUpdates.isAppearanceUpdated || stateUpdates.isFontUpdated {
          updateWindow()
        }
      }
    }

    updateWindow()
  }

  deinit {
    task?.cancel()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func updateWindow() {
    guard let window else {
      return
    }

    viewController.reloadData()

    if store.cmdlines.dictionary.isEmpty {
      parentWindow.removeChildWindow(window)
      window.setIsVisible(false)

    } else {
      parentWindow.addChildWindow(window, ordered: .above)
    }
  }

  func point(forCharacterLocation location: Int) -> CGPoint? {
    viewController.point(forCharacterLocation: location)
      .map {
        $0.applying(.init(
          translationX: window!.frame.origin.x,
          y: window!.frame.origin.y
        ))
      }
  }

  func windowDidResize(_: Notification) {
    window!.setFrameOrigin(.init(
      x: parentWindow.frame.origin.x + (parentWindow.frame.width - window!.frame.width) / 2,
      y: parentWindow.frame.origin.y + parentWindow.frame.height / 1.5
    ))
  }
}
