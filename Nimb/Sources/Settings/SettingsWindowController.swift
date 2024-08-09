// SPDX-License-Identifier: MIT

import AppKit

public class SettingsWindowController: NSWindowController, Rendering {
  init(store: Store) {
    self.store = store
    viewController = .init()
    customWindow.contentViewController = viewController
    super.init(window: customWindow)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func render() { }

  private class CustomWindow: NSPanel { }

  private let store: Store
  private let customWindow = CustomWindow(
    contentRect: .init(x: 0, y: 0, width: 400, height: 250),
    styleMask: [.closable, .titled],
    backing: .buffered,
    defer: true
  )
  private let viewController: SettingsViewController
}
