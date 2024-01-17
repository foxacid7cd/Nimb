// SPDX-License-Identifier: MIT

import AppKit

public class SettingsViewController: NSViewController {
  override public func loadView() {
    let stackView = NSStackView(views: [environmentView])
    stackView.orientation = .vertical
    view = stackView
  }

  private lazy var environmentView = SettingsEnvironmentView()
}
