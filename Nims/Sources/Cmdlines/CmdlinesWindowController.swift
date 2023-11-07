// SPDX-License-Identifier: MIT

import IdentifiedCollections
import Library
import SwiftUI
import TinyConstraints

public final class CmdlinesWindowController: NSWindowController {
  public init(store: Store, parentWindow: NSWindow) {
    self.store = store
    self.parentWindow = parentWindow

    viewController = CmdlinesViewController(store: store)

    let window = FloatingPanel(contentViewController: viewController)
    super.init(window: window)

    window.delegate = self
  }

  deinit {
    task?.cancel()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func render(_ stateUpdates: State.Updates) {
    if stateUpdates.isCmdlinesUpdated || stateUpdates.isFontUpdated || stateUpdates.isOuterGridLayoutUpdated {
      updateWindowFrameOrigin()
    }

    if stateUpdates.isCmdlinesUpdated || stateUpdates.isAppearanceUpdated || stateUpdates.isFontUpdated {
      updateWindow()
    }

    if stateUpdates.isCursorBlinkingPhaseUpdated || stateUpdates.isBusyUpdated {
      viewController.setNeedsDisplayCmdlineTextViews()
    }
  }

  private let store: Store
  private let parentWindow: NSWindow
  private let viewController: CmdlinesViewController
  private var task: Task<Void, Never>?
  private var isVisibleAnimatedOn: Bool?

  private var preferredWindowFrameOrigin: CGPoint {
    .init(
      x: parentWindow.frame.origin.x + (parentWindow.frame.width - window!.frame.width) / 2,
      y: parentWindow.frame.origin.y + parentWindow.frame.height / 1.5
    )
  }

  private func updateWindowFrameOrigin() {
    window!.setFrameOrigin(preferredWindowFrameOrigin)
  }

  private func updateWindow() {
    viewController.reloadData()

    let cmdlines = store.state.cmdlines
    if cmdlines.dictionary.isEmpty {
      if isVisibleAnimatedOn != false {
        NSAnimationContext.runAnimationGroup { context in
          context.duration = 0.12
          window!.animator().alphaValue = 0
        }
        isVisibleAnimatedOn = false
      }

    } else {
      if isVisibleAnimatedOn != true {
        if window!.parent == nil {
          parentWindow.addChildWindow(window!, ordered: .above)
          window!.alphaValue = 0
        }

        NSAnimationContext.runAnimationGroup { context in
          context.duration = 0.12
          window!.animator().alphaValue = 1
        }
        isVisibleAnimatedOn = true
      }
    }
  }
}

extension CmdlinesWindowController: NSWindowDelegate {
  public func windowDidResize(_: Notification) {
    updateWindowFrameOrigin()
  }
}
