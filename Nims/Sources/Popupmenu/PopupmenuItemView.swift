// SPDX-License-Identifier: MIT

import AppKit

public class PopupmenuItemView: NSView {
  public init(store: Store) {
    self.store = store
    super.init(frame: .zero)

    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
    textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    addSubview(textField)

    secondTextField.translatesAutoresizingMaskIntoConstraints = false
    secondTextField.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    secondTextField.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    addSubview(secondTextField)

    addConstraints([
      textField.leadingAnchor.constraint(equalTo: leadingAnchor),
      textField.centerYAnchor.constraint(equalTo: centerYAnchor),

      secondTextField.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 4),
      secondTextField.trailingAnchor.constraint(equalTo: trailingAnchor),
      secondTextField.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public static let ReuseIdentifier = NSUserInterfaceItemIdentifier(.init(describing: PopupmenuItemView.self))

  override public func draw(_ dirtyRect: NSRect) {
    let graphicsContext = NSGraphicsContext.current!
    let cgContext = graphicsContext.cgContext

    dirtyRect.clip()

    store.appearance.backgroundColor(for: isSelected ? .pmenuSel : .pmenu)
      .appKit
      .setFill()
    dirtyRect.fill()

    let roundedRectPath = CGPath(
      roundedRect: bounds.insetBy(dx: -8, dy: 0),
      cornerWidth: 5,
      cornerHeight: 5,
      transform: nil
    )
    cgContext.addPath(roundedRectPath)
    cgContext.drawPath(using: .fill)

    super.draw(dirtyRect)
  }

  public func set(item: PopupmenuItem, isSelected: Bool) {
    self.isSelected = isSelected
    needsDisplay = true

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
          .backgroundColor: store.appearance.backgroundColor(for: observedHighlightName).appKit,
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
  private var isSelected = false
}
