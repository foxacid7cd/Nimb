// SPDX-License-Identifier: MIT

import AppKit
import TinyConstraints

public class PopupmenuItemView: NSView {
  public static let reuseIdentifier = NSUserInterfaceItemIdentifier(
    String(describing: PopupmenuItemView.self)
  )

  public var item: PopupmenuItem?
  public var isSelected = false

  private let store: Store
  private let wordTextField = NSTextField(labelWithString: "")
  private let kindTextField = NSTextField(labelWithString: "")

  public init(store: Store) {
    self.store = store
    super.init(frame: .zero)

    clipsToBounds = true
    wantsLayer = true
    layer!.cornerRadius = 6

    wordTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)
    wordTextField.setContentCompressionResistancePriority(
      .defaultLow,
      for: .horizontal
    )
    addSubview(wordTextField)
    wordTextField.leading(to: self, offset: 11)
    wordTextField.topToSuperview(offset: 5)
    wordTextField.bottomToSuperview(offset: 4)

    kindTextField.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    kindTextField.setContentCompressionResistancePriority(
      .defaultHigh,
      for: .horizontal
    )
    addSubview(kindTextField)
    kindTextField.leadingToTrailing(of: wordTextField, offset: 5)
    kindTextField.centerYToSuperview()
    kindTextField.trailing(to: self, offset: -11)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

//  public func render() {
//    guard let item else {
//      return
//    }
//    let font = state.font
//    let appearance = state.appearance
//
//    layer!.backgroundColor = isSelected ? NSColor.selectedContentBackgroundColor.cgColor : NSColor
//      .black.withAlphaComponent(0).cgColor
//
//    let wordHighlightName: Appearance
//      .ObservedHighlightName = isSelected ? .pmenuSel : .pmenu
//    wordTextField.attributedStringValue = .init(
//      string: item.word,
//      attributes: [
//        .foregroundColor: NSColor.white,
//        .font: font.appKit(
//          isBold: appearance.isBold(for: wordHighlightName),
//          isItalic: appearance.isItalic(for: wordHighlightName)
//        ),
//      ]
//    )
//
//    let kindHighlightName: Appearance
//      .ObservedHighlightName = isSelected ? .pmenuKindSel : .pmenuKind
//    let kindAttributedString = NSMutableAttributedString(
//      string: item.kind,
//      attributes: [
//        .foregroundColor: appearance.foregroundColor(for: kindHighlightName)
//          .appKit,
//        .font: font.appKit(
//          isBold: appearance.isBold(for: kindHighlightName),
//          isItalic: appearance.isItalic(for: kindHighlightName)
//        ),
//      ]
//    )
//    if !item.menu.isEmpty {
//      let menuHighlightName: Appearance
//        .ObservedHighlightName = isSelected ? .pmenuExtraSel : .pmenuExtra
//      kindAttributedString.append(.init(
//        string: " \(item.menu)",
//        attributes: [
//          .foregroundColor: appearance.foregroundColor(for: menuHighlightName)
//            .with(alpha: 0.5)
//            .appKit,
//          .font: font.appKit(
//            isBold: appearance.isBold(for: menuHighlightName),
//            isItalic: appearance.isItalic(for: menuHighlightName)
//          ),
//        ]
//      ))
//    }
//    kindTextField.attributedStringValue = kindAttributedString
//  }
}
