// SPDX-License-Identifier: MIT

import AppKit

public class SettingsEnvironmentView: NSView {
  override public init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    setup()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)

    setup()
  }

  private class ItemView: NSView {
    override init(frame frameRect: NSRect) {
      super.init(frame: frameRect)

      setup()
    }

    required init?(coder: NSCoder) {
      super.init(coder: coder)

      setup()
    }

    static let reuseIdentifier = NSUserInterfaceItemIdentifier(
      String(describing: ItemView.self)
    )

    let nameTextField = NSTextField()
    let valueTextField = NSTextField()
    lazy var deleteButton = NSButton(
      title: "Delete",
      target: self,
      action: #selector(handleDeleteButtonAction)
    )
    var handleDelete: (() -> Void)?

    private func setup() {
      nameTextField.placeholderString = "Name"
      nameTextField.isEditable = true
      addSubview(nameTextField)
      nameTextField.leading(to: self)
      nameTextField.centerYToSuperview()

      valueTextField.placeholderString = "Value"
      valueTextField.isEditable = true
      addSubview(valueTextField)
      valueTextField.leadingToTrailing(of: nameTextField)
      valueTextField.centerYToSuperview()
      valueTextField.width(to: nameTextField, multiplier: 1.5)

      addSubview(deleteButton)
      deleteButton.leadingToTrailing(of: valueTextField)
      deleteButton.centerYToSuperview()
      deleteButton.trailing(to: self)
    }

    @objc private func handleDeleteButtonAction() {
      handleDelete?()
    }
  }

  private let scrollView = NSScrollView()
  private let tableView = NSTableView()

  private func setup() {
    scrollView.automaticallyAdjustsContentInsets = false
    scrollView.contentInsets = .zero
    scrollView.drawsBackground = false
    addSubview(scrollView)
    scrollView.edgesToSuperview()
    scrollView.size(.init(width: 400, height: 160), relation: .equalOrGreater)

    tableView.delegate = self
    tableView.dataSource = self
    tableView.headerView = nil
    tableView.addTableColumn(.init(identifier: ItemView.reuseIdentifier))
    tableView.style = .fullWidth
    tableView.selectionHighlightStyle = .none
    scrollView.documentView = tableView
    tableView.width(to: scrollView)
  }
}

extension SettingsEnvironmentView: NSTableViewDelegate, NSTableViewDataSource {
  public func numberOfRows(in tableView: NSTableView) -> Int {
    10
  }

  public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    var itemView = tableView.makeView(withIdentifier: ItemView.reuseIdentifier, owner: self) as? ItemView
    if itemView == nil {
      itemView = .init(frame: .zero)
      itemView!.identifier = ItemView.reuseIdentifier
    }
    itemView!.handleDelete = {
      print("Deleted \(row)")
    }
    return itemView
  }
}
