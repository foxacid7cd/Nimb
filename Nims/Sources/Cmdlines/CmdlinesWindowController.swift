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

    let window = NSPanel(contentViewController: viewController)
    window.styleMask = [.titled, .fullSizeContentView]
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.isMovable = false
    window.isOpaque = false
    window.isFloatingPanel = true
    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    window.level = .popUpMenu
    window.alphaValue = 0
    parentWindow.addChildWindow(window, ordered: .above)

    super.init(window: window)

    window.delegate = self

    parentWindowFrameObservation = parentWindow.observe(\.frame) { [weak self] _, _ in
      guard let self else {
        return
      }

      Task { @MainActor in
        self.updateWindowFrameOriginIfNeeded()
      }
    }
    updateWindow()
  }

  deinit {
    task?.cancel()
    parentWindowFrameObservation?.invalidate()
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
    updateWindowFrameOriginIfNeeded()
  }

  private let store: Store
  private let parentWindow: NSWindow
  private let viewController: CmdlinesViewController
  private var task: Task<Void, Never>?
  private var isVisibleAnimatedOn: Bool?
  private var parentWindowFrameObservation: NSKeyValueObservation?

  private var preferredWindowFrameOrigin: CGPoint {
    .init(
      x: parentWindow.frame.origin.x + (parentWindow.frame.width - window!.frame.width) / 2,
      y: parentWindow.frame.origin.y + parentWindow.frame.height / 1.5
    )
  }

  private func updateWindowFrameOriginIfNeeded() {
    let origin = preferredWindowFrameOrigin
    if origin != window!.frame.origin {
      window!.setFrame(
        .init(
          origin: origin,
          size: window!.frame.size
        ),
        display: true
      )
    }
  }

  private func updateWindow() {
    updateWindowFrameOriginIfNeeded()

    guard let window else {
      return
    }

    viewController.reloadData()

    let cmdlines = store.state.cmdlines
    if cmdlines.dictionary.isEmpty {
      if isVisibleAnimatedOn != false {
        NSAnimationContext.runAnimationGroup { context in
          context.duration = 0.12
          window.animator().alphaValue = 0
        }
        isVisibleAnimatedOn = false
      }

    } else {
      if isVisibleAnimatedOn != true {
        NSAnimationContext.runAnimationGroup { context in
          context.duration = 0.12
          window.animator().alphaValue = 1
        }
        isVisibleAnimatedOn = true
      }
    }
  }
}
