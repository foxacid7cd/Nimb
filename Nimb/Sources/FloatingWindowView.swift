// SPDX-License-Identifier: MIT

import AppKit

public class FloatingWindowView: NSVisualEffectView {
  private var isToggledOn: Bool?

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

  private func setup() {
    material = .menu
    blendingMode = .withinWindow

    wantsLayer = true
    layer!.cornerRadius = 8
    layer!.borderColor = NSColor.separatorColor.cgColor
    layer!.borderWidth = 0.5
    layer!.shadowOpacity = 0.8
    layer!.shadowRadius = 10
    layer!.shadowOffset = .init(width: 0, height: 10)
  }
}
