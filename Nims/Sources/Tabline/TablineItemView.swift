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
    textField.leading(to: self, offset: 8)
    textField.trailing(to: self, offset: -8)
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
  var isFirst = false
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
        .font: store.font.nsFont(),
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
    backgroundImageView.image = makeBackgroundImage(
      color: isSelected ? store.appearance.defaultForegroundColor.appKit : NSColor.textBackgroundColor
    )
  }

  private func makeBackgroundImage(color: NSColor) -> NSImage {
    let bounds = bounds
    let isFirst = isFirst

    return .init(size: .init(width: bounds.width + 16, height: bounds.height), flipped: false) { _ in
      let graphicsContext = NSGraphicsContext.current!
      let cgContext = graphicsContext.cgContext

      cgContext.beginPath()
      cgContext.move(to: .init())
      cgContext.addLine(to: .init(x: isFirst ? 0 : 8, y: bounds.height))
      cgContext.addLine(to: .init(x: bounds.width + 16, y: bounds.height))
      cgContext.addLine(to: .init(x: bounds.width + 8, y: 0))
      cgContext.closePath()

      color.setFill()
      cgContext.fillPath()

      return true
    }
  }
}
