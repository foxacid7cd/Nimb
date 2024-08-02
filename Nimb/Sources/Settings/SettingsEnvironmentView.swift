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

  private struct Item: Sendable, Hashable {
    var name: String
    var value: String
  }

  private class ItemView: NSView, NSTextFieldDelegate {
    override init(frame frameRect: NSRect) {
      super.init(frame: frameRect)

      setup()
    }

    required init?(coder: NSCoder) {
      super.init(coder: coder)

      setup()
    }

    let textField = NSTextField()
    var textChanged: ((String) -> Void)?

    func controlTextDidChange(_: Notification) {
      textChanged?(textField.stringValue)
    }

    private func setup() {
      textField.maximumNumberOfLines = 1
      textField.contentType = nil
      textField.isAutomaticTextCompletionEnabled = false
      textField.allowsEditingTextAttributes = false
      textField.placeholderString = "Text"
      textField.isEditable = true
      textField.delegate = self
      addSubview(textField)
      textField.leading(to: self)
      textField.trailing(to: self)
      textField.centerYToSuperview()
    }
  }

  private class ButtonView: NSView {
    override init(frame frameRect: NSRect) {
      super.init(frame: frameRect)

      setup()
    }

    required init?(coder: NSCoder) {
      super.init(coder: coder)

      setup()
    }

    lazy var button = NSButton(title: "Button", target: self, action: #selector(handleButtonAction))
    var handleAction: (() -> Void)?

    private func setup() {
      button.target = self
      addSubview(button)
      button.leading(to: self)
      button.trailing(to: self)
      button.centerYToSuperview()
    }

    @objc private func handleButtonAction() {
      handleAction?()
    }
  }

  private var items = [Item]()
  private let scrollView = NSScrollView()
  private let nameTableColumn = NSTableColumn(identifier: .init(rawValue: "name"))
  private let valueTableColumn = NSTableColumn(identifier: .init(rawValue: "value"))
  private let deleteTableColumn = NSTableColumn(identifier: .init(rawValue: "delete"))
  private let tableView = NSTableView()
  private let footerView = NSView()
  private lazy var addButton = NSButton(
    title: "Add",
    target: self,
    action: #selector(handleAddButtonAction)
  )
  private let statusTextField = NSTextField(labelWithString: "")

  private func setup() {
    loadEnvironmentOverlay()

    wantsLayer = true
    clipsToBounds = true
    layer!.cornerRadius = 8
    layer!.borderWidth = 1
    layer!.borderColor = NSColor.textColor.withAlphaComponent(0.2).cgColor

    scrollView.automaticallyAdjustsContentInsets = false
    scrollView.contentInsets = .init(top: 0, left: 0, bottom: 4, right: 0)
    scrollView.drawsBackground = false
    scrollView.clipsToBounds = true
    addSubview(scrollView)
    scrollView.leading(to: self)
    scrollView.trailing(to: self)
    scrollView.top(to: self)
    scrollView.size(.init(width: 400, height: 120), relation: .equalOrGreater)

    nameTableColumn.title = "Name"
    nameTableColumn.isEditable = true
    nameTableColumn.width = 120
    valueTableColumn.title = "Value"
    valueTableColumn.isEditable = true
    valueTableColumn.width = 180
    deleteTableColumn.title = "Action"
    deleteTableColumn.maxWidth = 50
    deleteTableColumn.minWidth = 50
    deleteTableColumn.isEditable = false
    tableView.addTableColumn(nameTableColumn)
    tableView.addTableColumn(valueTableColumn)
    tableView.addTableColumn(deleteTableColumn)

    tableView.delegate = self
    tableView.dataSource = self
    tableView.style = .fullWidth
    tableView.intercellSpacing = .zero
    tableView.selectionHighlightStyle = .none
    tableView.rowHeight = 22
    scrollView.documentView = tableView
    tableView.width(to: scrollView)

    addSubview(footerView)
    footerView.leading(to: self)
    footerView.trailing(to: self)
    footerView.topToBottom(of: scrollView)
    footerView.bottomToSuperview()

    footerView.addSubview(addButton)
    addButton.leading(to: footerView, offset: 4)
    addButton.topToSuperview(offset: 4)
    addButton.bottomToSuperview(offset: -4)
    addButton.width(50)

    footerView.addSubview(statusTextField)
    statusTextField.leadingToTrailing(of: addButton, offset: 4)
    statusTextField.centerY(to: addButton)
    statusTextField.trailing(to: footerView, offset: -4)
  }

  private func loadEnvironmentOverlay() {
    items = UserDefaults.standard.environmentOverlay
      .map { .init(name: $0.key, value: $0.value) }
  }

  private func saveEnvironmentOverlay() {
    var hasDuplicates = false
    var dictionary = [String: String]()
    for item in items {
      let trimmedName = item.name.trimmingCharacters(in: .whitespaces)
      guard !trimmedName.isEmpty else {
        continue
      }
      let oldValue = dictionary.updateValue(item.value, forKey: trimmedName)
      if oldValue != nil {
        hasDuplicates = true
      }
    }
    UserDefaults.standard.environmentOverlay = dictionary
    if hasDuplicates {
      statusTextField.attributedStringValue = .init(
        string: "Duplicate names!",
        attributes: [.foregroundColor: NSColor.red]
      )
    } else {
      statusTextField.attributedStringValue = .init()
    }
  }

  @objc private func handleAddButtonAction() {
    if let last = items.last, last.name.trimmingCharacters(in: .whitespaces).isEmpty {
      return
    }
    items.append(.init(name: "", value: ""))
    saveEnvironmentOverlay()
    tableView.reloadData()
    tableView.scrollRowToVisible(items.count - 1)
  }
}

extension SettingsEnvironmentView: NSTableViewDelegate, NSTableViewDataSource {
  public func numberOfRows(in tableView: NSTableView) -> Int {
    items.count
  }

  public func tableView(
    _ tableView: NSTableView,
    viewFor tableColumn: NSTableColumn?,
    row: Int
  )
    -> NSView?
  {
    let item = items[row]
    if tableColumn === nameTableColumn {
      var itemView = tableView.makeView(
        withIdentifier: nameTableColumn.identifier,
        owner: self
      ) as? ItemView
      if itemView == nil {
        itemView = .init(frame: .zero)
        itemView!.identifier = nameTableColumn.identifier
      }
      itemView!.textField.placeholderString = "Name"
      itemView!.textField.stringValue = item.name
      itemView!.textChanged = { [weak self] in
        guard let self else {
          return
        }
        items[row].name = $0
        saveEnvironmentOverlay()
      }
      return itemView
    } else if tableColumn === valueTableColumn {
      var itemView = tableView.makeView(
        withIdentifier: valueTableColumn.identifier,
        owner: self
      ) as? ItemView
      if itemView == nil {
        itemView = .init(frame: .zero)
        itemView!.identifier = valueTableColumn.identifier
      }
      itemView!.textField.placeholderString = "Value"
      itemView!.textField.stringValue = item.value
      itemView!.textChanged = { [weak self] in
        guard let self else {
          return
        }
        items[row].value = $0
        saveEnvironmentOverlay()
      }
      return itemView
    } else if tableColumn === deleteTableColumn {
      var buttonView = tableView.makeView(
        withIdentifier: deleteTableColumn.identifier,
        owner: self
      ) as? ButtonView
      if buttonView == nil {
        buttonView = .init(frame: .zero)
        buttonView!.identifier = deleteTableColumn.identifier
      }
      buttonView!.button.title = "Delete"
      buttonView!.handleAction = { [weak self] in
        guard let self else {
          return
        }
        items.remove(at: row)
        saveEnvironmentOverlay()
        tableView.reloadData()
      }
      return buttonView
    }
    return nil
  }
}
