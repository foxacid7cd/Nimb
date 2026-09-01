// SPDX-License-Identifier: MIT

import AppKit
import NimbState

class TablineItemView: NSView, Rendering {
  override var frame: NSRect {
    didSet {
      if frame != oldValue {
        shouldRedrawImageViews = true
        render()
      }
    }
  }

  var renderContext: RenderContext! = nil

  var isSelected = false
  var isLast = false
  var clicked: (() -> Void)? = nil
  var filledColor: NSColor? = nil

  var text = "" {
    didSet {
      if text != oldValue {
        shouldRedrawImageViews = true
        isAnimated = false
        render()
      }
    }
  }

  private let store: Store
  private let backgroundImageView = NSImageView()
  private let accentBackgroundImageView = NSImageView()
  private let textField = NSTextField(labelWithString: "")
  private var trackingArea: NSTrackingArea? = nil
  private var isMouseInside = false
  private var isPressed = false
  private var shouldRedrawImageViews = false
  private var isAnimated = false

  init(store: Store) {
    self.store = store
    super.init(frame: .zero)

    backgroundImageView.wantsLayer = true
    backgroundImageView.imageScaling = .scaleNone
    addSubview(backgroundImageView)
    backgroundImageView.centerInSuperview()

    accentBackgroundImageView.wantsLayer = true
    accentBackgroundImageView.imageScaling = .scaleNone
    addSubview(accentBackgroundImageView)
    accentBackgroundImageView.centerInSuperview()

    addSubview(textField)
    textField.leading(to: self, offset: 12)
    textField.trailing(to: self, offset: -12)
    textField.centerY(to: self)

    render()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    if let trackingArea {
      removeTrackingArea(trackingArea)
    }
    trackingArea = .init(
      rect: bounds,
      options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
      owner: self,
      userInfo: nil,
    )
    addTrackingArea(trackingArea!)
  }

  override func mouseEntered(with event: NSEvent) {
    isMouseInside = true
    render()
  }

  override func mouseExited(with event: NSEvent) {
    isMouseInside = false
    render()
  }

  /// The label and the background images are decoration. Taking every mouse
  /// event inside the item keeps a press from landing on one of them instead.
  override func hitTest(_ point: NSPoint) -> NSView? {
    let localPoint = superview.map { convert(point, from: $0) } ?? point
    return bounds.contains(localPoint) ? self : nil
  }

  override func mouseDown(with event: NSEvent) {
    setPressed(true)
  }

  /// A press follows the cursor out of the item and back in, the way every
  /// other button on the platform does.
  override func mouseDragged(with event: NSEvent) {
    setPressed(contains(event))
  }

  override func mouseUp(with event: NSEvent) {
    let wasPressed = isPressed
    setPressed(false)
    if wasPressed, contains(event) {
      clicked?()
    }
  }

  func render() {
    textField.attributedStringValue = .init(string: text)

    if shouldRedrawImageViews {
      redrawImageViews()
      shouldRedrawImageViews = false
    }

    // A press reads as the stronger version of a hover. Pressing lands at
    // once, an animation there lagging behind the finger; releasing fades back
    // like every other state change. These are views rather than layers, so the
    // duration has to come from NSAnimationContext: an animator proxy ignores a
    // CATransaction around it and animates at the default duration instead.
    let duration = isAnimated && !isPressed ? 0.07 : 0
    let backgroundAlpha: Double =
      if isSelected {
        0
      } else if isPressed {
        0.5
      } else if isMouseInside {
        0.75
      } else {
        1
      }
    let accentAlpha: Double =
      if isSelected {
        isPressed ? 0.75 : 1
      } else if isPressed {
        0.35
      } else if isMouseInside {
        0.15
      } else {
        0
      }
    let textAlpha: Double = isSelected || isMouseInside || isPressed ? 0.95 : 0.8

    NSAnimationContext.runAnimationGroup { context in
      context.duration = duration
      context.timingFunction = .init(name: .linear)

      func setAlpha(_ alpha: Double, of view: NSView) {
        if duration > 0 {
          view.animator().alphaValue = alpha
        } else {
          view.alphaValue = alpha
        }
      }

      setAlpha(backgroundAlpha, of: backgroundImageView)
      setAlpha(accentAlpha, of: accentBackgroundImageView)
      setAlpha(textAlpha, of: textField)
    }

    isAnimated = true
  }

  private func contains(_ event: NSEvent) -> Bool {
    bounds.contains(convert(event.locationInWindow, from: nil))
  }

  private func setPressed(_ isPressed: Bool) {
    guard isPressed != self.isPressed else {
      return
    }
    self.isPressed = isPressed
    render()
  }

  private func redrawImageViews() {
    let color = NSColor(white: 0.1, alpha: 1)
    let fill = SlantedBackgroundFill.gradient(
      from: color.withAlphaComponent(0.65),
      to: color.withAlphaComponent(0.4),
    )
    backgroundImageView.image = .makeSlantedBackground(
      isFlatRight: isLast,
      size: bounds.size,
      fill: fill,
    )
    backgroundImageView.image = .makeSlantedBackground(
      isFlatRight: isLast,
      size: bounds.size,
      fill: fill,
    )

    let accentColor = filledColor ?? .white
    let accentFill = SlantedBackgroundFill.gradient(
      from: accentColor.withAlphaComponent(0.35),
      to: accentColor.withAlphaComponent(0.6),
    )
    accentBackgroundImageView.image = .makeSlantedBackground(
      isFlatRight: isLast,
      size: bounds.size,
      fill: accentFill,
    )
  }

  private func makeAttributedString(for text: String) -> NSAttributedString {
    .init(
      string: text,
      attributes: [
        .font: NSFont.systemFont(
          ofSize: NSFont.systemFontSize * 0.92,
          weight: .medium,
        ),
        .foregroundColor: isSelected ? NSColor.labelColor : NSColor.secondaryLabelColor,
      ],
    )
  }

  private func makeFont(
    for highlightName: Appearance
      .ObservedHighlightName,
  )
    -> NSFont
  {
    var font = NSFont.systemFont(
      ofSize: NSFont.systemFontSize,
      weight: state.appearance.isBold(for: highlightName) ? .heavy : .semibold,
    )
    if state.appearance.isItalic(for: highlightName) {
      font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
    }
    return font
  }
}
