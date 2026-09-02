// SPDX-License-Identifier: MIT

import AppKit

private final class SettingsStartupViewController: NSViewController {
  private lazy var environmentView = SettingsEnvironmentView()
  private lazy var vimrcView = SettingsVimrcView()

  override func loadView() {
    let view = NSView(frame: .init(x: 0, y: 0, width: 520, height: 350))

    let note = startupNote()
    let stackView = NSStackView(views: [
      note,
      sectionHeaderView(title: "Vim configuration"),
      vimrcView,
      sectionHeaderView(title: "Additional environment variables"),
      environmentView,
    ])
    stackView.orientation = .vertical
    stackView.alignment = .leading
    stackView.spacing = 0
    view.addSubview(stackView)
    stackView.edgesToSuperview(insets: .init(
      top: 16,
      left: 16,
      bottom: 16,
      right: 16,
    ))

    stackView.setCustomSpacing(20, after: vimrcView)
    stackView.setCustomSpacing(20, after: note)
    vimrcView.width(to: environmentView)

    self.view = view
  }

  private func startupNote() -> NSView {
    let field = NSTextField(wrappingLabelWithString: "Startup changes apply after restarting Nimb.")
    field.textColor = .secondaryLabelColor
    return field
  }

  private func sectionHeaderView(title: String) -> NSView {
    let headerView = NSView()

    let textField = NSTextField(labelWithString: title)
    headerView.addSubview(textField)
    textField.edgesToSuperview(insets: .init(
      top: 0,
      left: 8,
      bottom: 4,
      right: 8,
    ))

    return headerView
  }
}

public final class SettingsViewController: NSTabViewController, Rendering {
  public var renderContext: RenderContext! = nil

  private let generalViewController: SettingsGeneralViewController
  private let advancedViewController: SettingsAdvancedViewController

  init(store: Store) {
    generalViewController = .init(store: store)
    advancedViewController = .init(store: store)
    super.init(nibName: nil, bundle: nil)

    tabStyle = .toolbar
    addTab(title: "General", symbol: "paintbrush", viewController: generalViewController)
    addTab(title: "Startup", symbol: "power", viewController: SettingsStartupViewController())
    addTab(title: "Advanced", symbol: "gearshape.2", viewController: advancedViewController)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func render() {
    renderChildren(generalViewController, advancedViewController)
  }

  private func addTab(title: String, symbol: String, viewController: NSViewController) {
    let item = NSTabViewItem(viewController: viewController)
    item.label = title
    item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
    addTabViewItem(item)
  }
}
