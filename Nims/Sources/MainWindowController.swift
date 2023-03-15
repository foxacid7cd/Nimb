// SPDX-License-Identifier: MIT

import AppKit

class MainWindowController: NSWindowController {
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

  init(store: Store, viewController: NSViewController) {
    let window = NSWindow(contentViewController: viewController)
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
