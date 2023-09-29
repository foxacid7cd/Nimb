// SPDX-License-Identifier: MIT

import AppKit
import Library
import Neovim

final class MainWindowController: NSWindowController {
  private let store: Store
  private let viewController: MainViewController

  var windowTitle = "" {
    didSet {
      if isWindowLoaded {
        window?.title = windowTitle
      }
    }
  }

  var windowBackgroundColor: NSColor? {
    get {
      window?.backgroundColor
    }
    set {
      window?.backgroundColor = newValue
    }
  }

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

    window?.title = windowTitle
  }

  func point(forGridID gridID: Grid.ID, gridPoint: IntegerPoint) -> CGPoint? {
    viewController.point(forGridID: gridID, gridPoint: gridPoint)
      .map {
        $0.applying(.init(
          translationX: window!.frame.origin.x,
          y: window!.frame.origin.y
        ))
      }
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
