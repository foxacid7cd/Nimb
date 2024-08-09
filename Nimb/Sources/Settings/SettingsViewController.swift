// SPDX-License-Identifier: MIT

import AppKit

public class SettingsViewController: NSViewController {
  private lazy var environmentView = SettingsEnvironmentView()
  private lazy var vimrcView = SettingsVimrcView()

  override public func loadView() {
    let view = NSView()

    let stackView = NSStackView(views: [
      sectionHeaderView(title: "Additional environment variables:"),
      environmentView,
      sectionHeaderView(title: "Use following vimrc:"),
      vimrcView,
    ])
    stackView.orientation = .vertical
    stackView.alignment = .leading
    stackView.spacing = 0
    view.addSubview(stackView)
    stackView.edgesToSuperview(insets: .init(
      top: 16,
      left: 16,
      bottom: 16,
      right: 16
    ))

    stackView.setCustomSpacing(16, after: environmentView)
    vimrcView.width(to: environmentView)

    self.view = view
  }

  private func sectionHeaderView(title: String) -> NSView {
    let headerView = NSView()

    let textField = NSTextField(labelWithString: title)
    headerView.addSubview(textField)
    textField.edgesToSuperview(insets: .init(
      top: 0,
      left: 8,
      bottom: 4,
      right: 8
    ))

    return headerView
  }
}
