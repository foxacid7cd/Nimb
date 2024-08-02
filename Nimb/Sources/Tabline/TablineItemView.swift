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
    textField.leading(to: self, offset: 12)
    textField.trailing(to: self, offset: -12)
    textField.centerY(to: self)

    trackingArea = .init(
      rect: bounds,
      options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
      owner: self,
      userInfo: nil
    )
    addTrackingArea(trackingArea!)

    let clickGestureRecognizer = NSClickGestureRecognizer(
      target: self,
      action: #selector(handleClick)
    )
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
  var filledColor: NSColor?

  override func layout() {
    super.layout()

    render()
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
    let color = filledColor ?? .white
    let fill: SlantedBackgroundFill =
      if isSelected {
        .gradient(
          from: color.withAlphaComponent(0.75),
          to: color.withAlphaComponent(0.35)
        )
      } else {
        .color(NSColor.black.withAlphaComponent(0.2))
      }
    backgroundImageView.image = .makeSlantedBackground(
      isFlatRight: isLast,
      size: bounds.size,
      fill: fill
    )
    textField.attributedStringValue = makeAttributedString(for: text)
  }

  private let store: Store
  private let backgroundImageView = NSImageView()
  private let textField = NSTextField(labelWithString: "")
  private var trackingArea: NSTrackingArea?
  private var isMouseInside = false

  private func makeAttributedString(for text: String) -> NSAttributedString {
    .init(
      string: text,
      attributes: [
        .font: NSFont.systemFont(
          ofSize: NSFont.systemFontSize,
          weight: .medium
        ),
        .foregroundColor: NSColor.windowFrameTextColor,
      ]
    )
  }

  private func makeFont(
    for highlightName: Appearance
      .ObservedHighlightName
  )
    -> NSFont
  {
    var font = NSFont.systemFont(
      ofSize: NSFont.systemFontSize,
      weight: store.appearance.isBold(for: highlightName) ? .heavy : .semibold
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
