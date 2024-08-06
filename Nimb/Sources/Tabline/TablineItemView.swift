// SPDX-License-Identifier: MIT

import AppKit

final class TablineItemView: NSView {
  init(store: Store) {
    self.store = store
    super.init(frame: .zero)

    backgroundImageView.imageScaling = .scaleNone
    addSubview(backgroundImageView)
    backgroundImageView.centerInSuperview()

    accentBackgroundImageView.imageScaling = .scaleNone
    addSubview(accentBackgroundImageView)
    accentBackgroundImageView.centerInSuperview()

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

  var isSelected = false
  var isLast = false
  var clicked: (() -> Void)?
  var filledColor: NSColor?

  var text = "" {
    didSet {
      if text != oldValue {
        shouldRedrawImageViews = true
      }
    }
  }

  override func layout() {
    super.layout()

    shouldRedrawImageViews = true
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
    textField.attributedStringValue = makeAttributedString(for: text)

    if shouldRedrawImageViews {
      redrawImageViews()
      shouldRedrawImageViews = false
    }
    CATransaction.begin()
    CATransaction.setAnimationDuration(0.1)
    backgroundImageView.animator().alphaValue = isSelected ? 0 : 1
    accentBackgroundImageView.animator().alphaValue = isSelected ? 1 : 0
    CATransaction.commit()
  }

  private let store: Store
  private let backgroundImageView = NSImageView()
  private let accentBackgroundImageView = NSImageView()
  private let textField = NSTextField(labelWithString: "")
  private var trackingArea: NSTrackingArea?
  private var isMouseInside = false
  private var shouldRedrawImageViews = false

  private func redrawImageViews() {
    let color = NSColor.black
    let fill = SlantedBackgroundFill.gradient(
      from: color.withAlphaComponent(0.4),
      to: color.withAlphaComponent(0.3)
    )
    backgroundImageView.image = .makeSlantedBackground(
      isFlatRight: isLast,
      size: bounds.size,
      fill: fill
    )
    backgroundImageView.image = .makeSlantedBackground(
      isFlatRight: isLast,
      size: bounds.size,
      fill: fill
    )

    let accentColor = filledColor ?? .white
    let accentFill = SlantedBackgroundFill.gradient(
      from: accentColor.withAlphaComponent(0.7),
      to: accentColor.withAlphaComponent(0.4)
    )
    accentBackgroundImageView.image = .makeSlantedBackground(
      isFlatRight: isLast,
      size: bounds.size,
      fill: accentFill
    )
  }

  private func makeAttributedString(for text: String) -> NSAttributedString {
    .init(
      string: text,
      attributes: [
        .font: NSFont.systemFont(
          ofSize: NSFont.systemFontSize * 0.92,
          weight: .medium
        ),
        .foregroundColor: isSelected ? NSColor.labelColor : NSColor.secondaryLabelColor,
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
