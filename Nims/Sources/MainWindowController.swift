// SPDX-License-Identifier: MIT

import AppKit

class MainWindowController: NSWindowController {
  init(viewController: NSViewController) {
    let window = NSWindow(contentViewController: viewController)
    window.styleMask = [.titled, .miniaturizable]

    super.init(window: window)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
