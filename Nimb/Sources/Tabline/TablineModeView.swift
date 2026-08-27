// SPDX-License-Identifier: MIT

import AppKit
import NimbState

/// The current mode, as a slanted colour panel filling the space under the
/// window buttons. Colour alone, since a label there would collide with them.
final class TablineModeView: NSView {
  /// What the window's traffic light buttons occupy. The panel is exactly that
  /// wide, so nothing shifts as the mode changes.
  static let trafficLightsWidth: CGFloat = 68
  static let trafficLightsTrailingInset: CGFloat = 12

  override var frame: NSRect {
    didSet {
      if frame != oldValue {
        redrawBackground()
      }
    }
  }

  var mode: String? = nil {
    didSet {
      if mode != oldValue {
        renderMode()
      }
    }
  }

  var isApplicationActive = true {
    didSet {
      if isApplicationActive != oldValue {
        renderMode()
      }
    }
  }

  private let backgroundImageView = NSImageView()

  init() {
    super.init(frame: .zero)

    wantsLayer = true

    backgroundImageView.wantsLayer = true
    backgroundImageView.imageScaling = .scaleNone
    addSubview(backgroundImageView)
    backgroundImageView.centerInSuperview()

    renderMode()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// The colour that stands for a mode. Neovim reports the mode name and
  /// nothing about how to colour it, so these are chosen here.
  private static func color(forMode mode: String) -> NSColor {
    switch mode {
    case let mode where mode.hasPrefix("insert"):
      .systemGreen
    case let mode where mode.hasPrefix("replace"):
      .systemRed
    case let mode where mode.hasPrefix("visual"),
         let mode where mode.hasPrefix("select"):
      .systemPurple
    case let mode where mode.hasPrefix("cmdline"):
      .systemYellow
    case let mode where mode.hasPrefix("terminal"):
      .systemTeal
    case let mode where mode.hasPrefix("operator"):
      .systemOrange
    default:
      .systemBlue
    }
  }

  private func renderMode() {
    guard mode != nil else {
      isHidden = true
      return
    }
    isHidden = false
    alphaValue = isApplicationActive ? 0.8 : 0.7
    redrawBackground()
  }

  private func redrawBackground() {
    guard let mode, !bounds.isEmpty else {
      return
    }
    let color = Self.color(forMode: mode)
    backgroundImageView.image = .makeSlantedBackground(
      // Flat against the window edge, slanted where it meets the buffers, so it
      // reads as the start of that run.
      isFlatLeft: true,
      size: bounds.size,
      fill: .gradient(
        from: color.withAlphaComponent(0.85),
        to: color.withAlphaComponent(0.6),
      ),
    )
  }
}
