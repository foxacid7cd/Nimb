// SPDX-License-Identifier: MIT

import AppKit
import CasePaths

public class SettingsVimrcView: NSView {
  override public init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    setup()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)

    setup()
  }

  private enum Item: String, CaseIterable {
    case `default` = "Default"
    case norc = "NORC"
    case none = "NONE"
    case custom = "Custom"
  }

  private let popUpButton = NSPopUpButton(frame: .zero, pullsDown: true)
  private let pathTextField = NSTextField(labelWithString: "~/.config/nvim/init.lua")
  private lazy var folderButton = NSButton(
    image: .init(
      systemSymbolName: "folder.fill",
      variableValue: 0,
      accessibilityDescription: nil
    )!,
    target: self,
    action: #selector(handleFolderButtonAction)
  )
  private var vimrc = Vimrc.default

  private func setup() {
    wantsLayer = true
    clipsToBounds = true
    layer!.cornerRadius = 8
    layer!.borderWidth = 1
    layer!.borderColor = NSColor.textColor.withAlphaComponent(0.2).cgColor

    let cell = NSPopUpButtonCell(textCell: "")

    popUpButton.cell = cell
    popUpButton.target = self
    popUpButton.action = #selector(handlePopUpButtonAction)
    popUpButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    popUpButton.autoenablesItems = true

    pathTextField.maximumNumberOfLines = 0
    pathTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)
    pathTextField.alphaValue = 0.3

    folderButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    folderButton.isEnabled = false

    let stackView = NSStackView(views: [popUpButton, pathTextField, folderButton])
    stackView.orientation = .horizontal
    stackView.alignment = .firstBaseline
    stackView.distribution = .fill
    stackView.spacing = 8
    addSubview(stackView)
    stackView.edgesToSuperview(insets: .init(top: 4, left: 4, bottom: 4, right: 4))

    reloadData()
  }

  private func reloadData() {
    vimrc = UserDefaults.standard.vimrc

    let selectedItem: Item = switch vimrc {
    case .default:
      .default
    case .norc:
      .norc
    case .none:
      .none
    case .custom:
      .custom
    }
    let indexOfSelectedItem = Item.allCases.firstIndex(of: selectedItem)!

    popUpButton.removeAllItems()
    let items = Item.allCases.map(\.rawValue)
    popUpButton.addItems(withTitles: items)
    if indexOfSelectedItem > 0 {
      popUpButton.selectItem(at: indexOfSelectedItem)
      popUpButton.setTitle(items[indexOfSelectedItem])
    }

    switch vimrc {
    case .default,
         .none,
         .norc:
      pathTextField.alphaValue = 0.3
      pathTextField.stringValue = FileManager.default.homeDirectoryForCurrentUser.path()
      folderButton.isEnabled = false
    case let .custom(url):
      pathTextField.alphaValue = 1
      pathTextField.stringValue = url.path()
      folderButton.isEnabled = true
    }
  }

  @objc private func handleFolderButtonAction() {}

  @objc private func handlePopUpButtonAction() {
    let selectedItem = Item.allCases[popUpButton.indexOfSelectedItem]
    let vimrc: Vimrc = switch selectedItem {
    case .default:
      .default
    case .norc:
      .norc
    case .none:
      .none
    case .custom:
      .custom(FileManager.default.homeDirectoryForCurrentUser)
    }
    UserDefaults.standard.vimrc = vimrc

    reloadData()
  }
}
