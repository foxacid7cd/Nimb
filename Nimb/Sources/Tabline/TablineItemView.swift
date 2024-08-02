// SPDX-License-Identifier: MIT

import AppKit

final class TablineItemView: NSView {
  init(store: Store) {
    self.store = store
    super.init(frame: .zero)

    backgroundImageView.imageScaling = .scaleNone
    addSubview(backgroundImageView)
    backgroundImageView.centerInSuperview()

    addSubview(textField)
    textField.leading(to: self, offset: 10)
    textField.trailing(to: self, offset: -10)
    textField.centerY(to: self)

    addSubview(selectedTextField)
    selectedTextField.center(in: textField)
    selectedTextField.isHidden = true

    trackingArea = .init(
      rect: bounds,
      options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
      owner: self,
      userInfo: nil
    )
    addTrackingArea(trackingArea!)

    let clickGestureRecognizer = NSClickGestureRecognizer(target: self, action: #selector(handleClick))
    clickGestureRecognizer.delaysPrimaryMouseButtonEvents = true
    addGestureRecognizer(clickGestureRecognizer)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var text = ""
  var isSelected = false
  var isLast = false
  var clicked: (() -> Void)?

  override func layout() {
    super.layout()

    renderBackgroundImage()
  }

  override func mouseEntered(with event: NSEvent) {
    isMouseInside = true
    render()
  }

  override func mouseExited(with event: NSEvent) {
    isMouseInside = false
    render()
  }

  func render() {
    renderBackgroundImage()

    textField.attributedStringValue = .init(
      string: text,
      attributes: [
        .font: makeFont(for: .tabLine),
        .foregroundColor: store.appearance
          .foregroundColor(for: .tabLine)
          .appKit
          .highlight(withLevel: isMouseInside ? 0.1 : 0)!,
      ]
    )
    textField.isHidden = isSelected

    selectedTextField.attributedStringValue = .init(
      string: text,
      attributes: [
        .font: makeFont(for: .tabLineSel),
        .foregroundColor: store.appearance
          .foregroundColor(for: .tabLineSel)
          .appKit,
      ]
    )
    selectedTextField.isHidden = !isSelected
  }

  private let store: Store
  private let backgroundImageView = NSImageView()
  private let textField = NSTextField(labelWithString: "")
  private let selectedTextField = NSTextField(labelWithString: "")
  private var trackingArea: NSTrackingArea?
  private var isMouseInside = false

  private func renderBackgroundImage() {
    let color = if isSelected {
      store.appearance
        .backgroundColor(for: .tabLineSel)
        .appKit
    } else {
      store.appearance
        .backgroundColor(for: .tabLine)
        .appKit
    }
    backgroundImageView.image = .makeSlantedBackground(
      isFlatRight: isLast,
      size: bounds.size,
      fill: .color(color)
    )
  }

  private func makeFont(for highlightName: Appearance.ObservedHighlightName) -> NSFont {
    var font = NSFont.systemFont(
      ofSize: NSFont.systemFontSize,
      weight: store.appearance.isBold(for: highlightName) ? .medium : .regular
    )
    if store.appearance.isItalic(for: highlightName) {
      font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
    }
    return font
  }

  @objc private func handleClick(_: NSClickGestureRecognizer) {
    clicked?()
  }
}
