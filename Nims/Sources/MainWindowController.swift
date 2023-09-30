// SPDX-License-Identifier: MIT

import AppKit
import Library
import Neovim

final class MainWindowController: NSWindowController {
  init(store: Store, viewController: MainViewController) {
    self.store = store
    self.viewController = viewController

    let window = NimsNSWindow(contentViewController: viewController)
    window.styleMask = [.titled, .miniaturizable, .resizable]

    super.init(window: window)

    window.delegate = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func windowDidLoad() {
    super.windowDidLoad()

    updateWindow()
  }

  func render(_ stateUpdates: State.Updates) {
    if stateUpdates.isAppearanceUpdated {
      updateWindow()
    }
    if stateUpdates.isTitleUpdated {
      updateWindow()
    }

    viewController.render(stateUpdates)
  }

  func point(forGridID gridID: Grid.ID, gridPoint: IntegerPoint) -> CGPoint? {
    viewController.point(forGridID: gridID, gridPoint: gridPoint)
      .map { $0 + window!.frame.origin }
  }

  private let store: Store
  private let viewController: MainViewController

  private func updateWindow() {
    window!.backgroundColor = store.appearance.defaultBackgroundColor.appKit
    window!.title = store.title ?? ""
  }
}

extension MainWindowController: NSWindowDelegate {
  func windowDidResize(_: Notification) {
    if !window!.inLiveResize {
      viewController.reportOuterGridSizeChangedIfNeeded()
    }
  }

  func windowWillStartLiveResize(_: Notification) {
    viewController.showMainView(on: false)
  }

  func windowDidEndLiveResize(_: Notification) {
    viewController.reportOuterGridSizeChangedIfNeeded()
    viewController.showMainView(on: true)
  }
}
