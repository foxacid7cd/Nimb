// SPDX-License-Identifier: MIT

import AppKit
import Neovim

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

    trackingArea = .init(
      rect: bounds,
      options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
      owner: self,
      userInfo: nil
    )
    addTrackingArea(trackingArea!)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var text = ""
  var isSelected = false
  var isLast = false
  var mouseDownObserver: (() -> Void)?

  override func layout() {
    super.layout()

    renderBackgroundImage()
  }

  override func mouseDown(with event: NSEvent) {
    mouseDownObserver?()
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

    let foregroundColor = if isSelected {
      NSColor.textBackgroundColor
    } else if isMouseInside {
      NSColor.textColor.withAlphaComponent(0.6)
    } else {
      NSColor.textColor.withAlphaComponent(0.3)
    }
    textField.attributedStringValue = .init(
      string: text,
      attributes: [
        .font: NSFont.labelFont(ofSize: NSFont.systemFontSize(for: .regular)),
        .foregroundColor: foregroundColor,
      ]
    )
  }

  private let store: Store
  private let backgroundImageView = NSImageView()
  private let textField = NSTextField(labelWithString: "")
  private var trackingArea: NSTrackingArea?
  private var isMouseInside = false

  private func renderBackgroundImage() {
    let color = isSelected ? NSColor.textColor : NSColor.textBackgroundColor
    backgroundImageView.image = .makeSlantedBackground(
      isFlatRight: isLast,
      size: bounds.size,
      fill: .gradient(from: color.withAlphaComponent(0.7), to: color)
    )
  }
}
