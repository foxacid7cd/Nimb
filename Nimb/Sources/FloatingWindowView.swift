// SPDX-License-Identifier: MIT

import AppKit

public class FloatingWindowView: NSVisualEffectView {
  override public init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  @discardableResult
  public func toggle(on: Bool) -> Bool {
    if on {
      if isToggledOn != true {
        isToggledOn = true
        isHidden = false
        NSAnimationContext.runAnimationGroup { context in
          context.duration = 0.1
          context.timingFunction = .init(name: .linear)
          let animator = animator()
          animator.alphaValue = 1
        }
        return true
      }
    } else {
      if isToggledOn != false {
        isToggledOn = false
        alphaValue = 0
        isHidden = true
        return true
      }
    }
    return false
  }

  ///  private let store: Store
  private var isToggledOn: Bool?

  private func setup() {
    material = .menu
    blendingMode = .withinWindow

    wantsLayer = true
    layer!.cornerRadius = 8
    layer!.borderColor = NSColor.separatorColor.cgColor
    layer!.borderWidth = 1
    layer!.shadowOpacity = 0.9
    layer!.shadowRadius = 10
    layer!.shadowOffset = .init(width: 0, height: 10)
  }
}
