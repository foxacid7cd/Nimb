// SPDX-License-Identifier: MIT

import AppKit
import NimbState

/// The current mode, as a slanted colour panel at the leading end of the
/// tabline.
///
/// It fills the space under the window's close, minimise and zoom buttons,
/// which sit over the tabline rather than in a bar of their own, so those
/// leading points were reserved and empty anyway. Colour alone, with no
/// label: the mode is something to catch out of the corner of the eye while
/// reading somewhere else, and text there would collide with the buttons.
final class TablineModeView: NSView {
  /// What the window's traffic light buttons occupy, measured from the
  /// leading edge. The panel is exactly that wide, so the buffers beside it
  /// start where they always did and nothing shifts as the mode changes.
  static let trafficLightsWidth: CGFloat = 68

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

  /// The colour that stands for a mode.
  ///
  /// Neovim has no per-mode highlight group to read this from -- it reports
  /// the mode name and nothing about how to colour it -- so these are chosen
  /// here, in the hues editors have converged on for them.
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
    alphaValue = isApplicationActive ? 1 : 0.7
    redrawBackground()
  }

  private func redrawBackground() {
    guard let mode, !bounds.isEmpty else {
      return
    }
    let color = Self.color(forMode: mode)
    backgroundImageView.image = .makeSlantedBackground(
      // Flat against the window's leading edge, slanted where it meets the
      // buffers, so it reads as the start of the same run rather than as a
      // separate panel.
      isFlatLeft: true,
      size: bounds.size,
      fill: .gradient(
        from: color.withAlphaComponent(0.85),
        to: color.withAlphaComponent(0.6),
      ),
    )
  }
}
