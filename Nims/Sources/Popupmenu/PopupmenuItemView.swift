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

    (isSelected ? darkerAccentColor : .clear)
      .setFill()

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
    let secondaryText = [item.kind, item.menu, item.info]
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: " ")

    accentColor = NSColor(
      hueSource: "".padding(
        toLength: secondaryText.count * 4,
        withPad: secondaryText,
        startingAt: 0
      ),
      saturation: 0.7,
      brightness: 0.7
    )
    darkerAccentColor = accentColor.withAlphaComponent(0.5)

    self.isSelected = isSelected
    needsDisplay = true

    textField.attributedStringValue = .init(string: item.word, attributes: [
      .foregroundColor: NSColor.textColor,
      .font: store.font.appKit(),
    ])

    secondTextField.attributedStringValue = .init(string: secondaryText, attributes: [
      .foregroundColor: isSelected ? NSColor.textColor : accentColor,
      .font: store.font.appKit(isItalic: true),
    ])
  }

  private let store: Store
  private let textField = NSTextField(labelWithString: "")
  private let secondTextField = NSTextField(labelWithString: "")
  private var isSelected = false
  private var accentColor = NSColor.white
  private var darkerAccentColor = NSColor.white
}
