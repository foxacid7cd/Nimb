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

    wordTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)
    wordTextField.setContentCompressionResistancePriority(
      .defaultLow,
      for: .horizontal
    )
    addSubview(wordTextField)
    wordTextField.leading(to: self, offset: 7)
    wordTextField.centerYToSuperview()

    kindTextField.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    kindTextField.setContentCompressionResistancePriority(
      .defaultHigh,
      for: .horizontal
    )
    addSubview(kindTextField)
    kindTextField.leadingToTrailing(of: wordTextField, offset: 5)
    kindTextField.centerYToSuperview()
    kindTextField.trailing(to: self, offset: -7)
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
    let font = store.font
    let appearance = store.appearance

    layer!.backgroundColor = appearance
      .backgroundColor(for: isSelected ? .pmenuSel : .pmenu)
      .appKit
      .cgColor

    let wordHighlightName: Appearance
      .ObservedHighlightName = isSelected ? .pmenuSel : .pmenu
    wordTextField.attributedStringValue = .init(
      string: item.word,
      attributes: [
        .foregroundColor: appearance.foregroundColor(for: wordHighlightName)
          .appKit,
        .font: font.appKit(
          isBold: appearance.isBold(for: wordHighlightName),
          isItalic: appearance.isItalic(for: wordHighlightName)
        ),
      ]
    )

    let kindHighlightName: Appearance
      .ObservedHighlightName = isSelected ? .pmenuKindSel : .pmenuKind
    let kindAttributedString = NSMutableAttributedString(
      string: item.kind,
      attributes: [
        .foregroundColor: appearance.foregroundColor(for: kindHighlightName)
          .appKit,
        .font: font.appKit(
          isBold: appearance.isBold(for: kindHighlightName),
          isItalic: appearance.isItalic(for: kindHighlightName)
        ),
      ]
    )
    if !item.menu.isEmpty {
      let menuHighlightName: Appearance
        .ObservedHighlightName = isSelected ? .pmenuExtraSel : .pmenuExtra
      kindAttributedString.append(.init(
        string: " \(item.menu)",
        attributes: [
          .foregroundColor: appearance.foregroundColor(for: menuHighlightName)
            .with(alpha: 0.5)
            .appKit,
          .font: font.appKit(
            isBold: appearance.isBold(for: menuHighlightName),
            isItalic: appearance.isItalic(for: menuHighlightName)
          ),
        ]
      ))
    }
    kindTextField.attributedStringValue = kindAttributedString
  }

  private let store: Store
  private let wordTextField = NSTextField(labelWithString: "")
  private let kindTextField = NSTextField(labelWithString: "")
}
