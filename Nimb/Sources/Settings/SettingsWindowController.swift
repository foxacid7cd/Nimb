// SPDX-License-Identifier: MIT

import AppKit

public class SettingsWindowController: NSWindowController, Rendering {
  private class CustomWindow: NSPanel { }

  public var renderContext: RenderContext! = nil

  private let customWindow = CustomWindow(
    contentRect: .init(x: 0, y: 0, width: 520, height: 420),
    styleMask: [.closable, .titled],
    backing: .buffered,
    defer: true,
  )
  private let viewController: SettingsViewController

  init(store: Store) {
    viewController = .init(store: store)
    customWindow.contentViewController = viewController
    customWindow.title = "Settings"
    customWindow.toolbarStyle = .preference
    customWindow.isReleasedWhenClosed = false
    customWindow.center()
    super.init(window: customWindow)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func render() {
    renderChildren(viewController)
  }
}
