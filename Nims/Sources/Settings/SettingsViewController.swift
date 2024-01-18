// SPDX-License-Identifier: MIT

import AppKit

public class SettingsViewController: NSViewController {
  override public func loadView() {
    let view = NSView()

    let stackView = NSStackView(views: [
      sectionHeaderView(title: "Additional environment variables:"),
      environmentView,
    ])
    stackView.orientation = .vertical
    stackView.alignment = .leading
    stackView.spacing = 0
    view.addSubview(stackView)
    stackView.edgesToSuperview(insets: .init(top: 15, left: 16, bottom: 16, right: 16))

    self.view = view
  }

  private lazy var environmentView = SettingsEnvironmentView()

  private func sectionHeaderView(title: String) -> NSView {
    let headerView = NSView()

    let textField = NSTextField(labelWithString: title)
    headerView.addSubview(textField)
    textField.edgesToSuperview(insets: .init(top: 0, left: 8, bottom: 4, right: 8))

    return headerView
  }
}
