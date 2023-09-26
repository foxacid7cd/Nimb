// SPDX-License-Identifier: MIT

import AppKit
import Library
import Neovim

final class MainWindowController: NSWindowController {
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
    self.viewController = viewController

    let window = Window(contentViewController: viewController)
    window.styleMask = [.titled, .miniaturizable]

    super.init(window: window)

    windowFrameAutosaveName = "Main"
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func windowDidLoad() {
    super.windowDidLoad()

    window?.title = windowTitle
  }
}

private final class Window: NSWindow {
  override var canBecomeKey: Bool {
    true
  }

  override var canBecomeMain: Bool {
    true
  }
}

extension MainWindowController: GridWindowFrameTransformer {
  func frame(forGridID gridID: Grid.ID, gridFrame: IntegerRectangle) -> CGRect? {
    guard let window, let frame = viewController.frame(forGridID: gridID, gridFrame: gridFrame) else {
      return nil
    }

    return window.frameRect(forContentRect: frame)
  }
}
