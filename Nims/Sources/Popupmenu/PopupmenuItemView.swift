// SPDX-License-Identifier: MIT

import AppKit
import TinyConstraints

public class PopupmenuItemView: NSView {
  public init(store: Store) {
    self.store = store
    super.init(frame: .zero)

    clipsToBounds = true
    wantsLayer = true
    layer!.cornerRadius = 5

    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
    textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    addSubview(textField)
    textField.leading(to: self, offset: 5)
    textField.centerYToSuperview()

    secondTextField.translatesAutoresizingMaskIntoConstraints = false
    secondTextField.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    secondTextField.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    addSubview(secondTextField)
    secondTextField.leadingToTrailing(of: textField, offset: 5)
    secondTextField.centerYToSuperview()
    secondTextField.trailing(to: self, offset: -5)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public static let reuseIdentifier = NSUserInterfaceItemIdentifier(
    String(describing: PopupmenuItemView.self)
  )

  public var item: PopupmenuItem?
  public var isSelected = false

  public func render() {
    guard let item else {
      return
    }

    layer!.backgroundColor = store.appearance
      .backgroundColor(for: isSelected ? .pmenuSel : .pmenu)
      .appKit
      .cgColor

    let observedHighlightName: Appearance.ObservedHighlightName = isSelected ? .pmenuSel : .pmenu
    textField.attributedStringValue = .init(string: item.word, attributes: [
      .foregroundColor: store.state.appearance.foregroundColor(for: observedHighlightName).appKit,
      .font: store.font.appKit(
        isBold: store.state.appearance.isBold(for: observedHighlightName),
        isItalic: store.state.appearance.isItalic(for: observedHighlightName)
      ),
    ])

    var secondaryTextParts = [SecondaryTextPart]()

    let kind = item.kind.trimmingCharacters(in: .whitespaces)
    if !kind.isEmpty {
      secondaryTextParts.append(.kind(kind))
    }

    let extra = [item.menu, item.info]
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }
      .joined(separator: " ")
    if !extra.isEmpty {
      secondaryTextParts.append(.extra(extra))
    }

    let secondaryTextAttributedString = NSMutableAttributedString()
    for (index, part) in secondaryTextParts.enumerated() {
      if index > 0 {
        secondaryTextAttributedString.append(.init(
          string: " ",
          attributes: [.font: store.font.appKit()]
        ))
      }
      let text: String
      let observedHighlightName: Appearance.ObservedHighlightName
      switch part {
      case let .kind(kind):
        text = kind
        observedHighlightName = isSelected ? .pmenuKindSel : .pmenuKind
      case let .extra(extra):
        text = extra
        observedHighlightName = isSelected ? .pmenuExtraSel : .pmenuExtra
      }
      secondaryTextAttributedString.append(.init(
        string: text,
        attributes: [
          .font: store.font.appKit(
            isBold: store.appearance.isBold(for: observedHighlightName),
            isItalic: store.appearance.isItalic(for: observedHighlightName)
          ),
          .foregroundColor: store.appearance.foregroundColor(for: observedHighlightName).appKit,
        ]
      ))
    }
    secondTextField.attributedStringValue = secondaryTextAttributedString

    enum SecondaryTextPart {
      case kind(String)
      case extra(String)
    }
  }

  private let store: Store
  private let textField = NSTextField(labelWithString: "")
  private let secondTextField = NSTextField(labelWithString: "")
}
