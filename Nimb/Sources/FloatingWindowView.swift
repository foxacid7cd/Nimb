// SPDX-License-Identifier: MIT

import AppKit

public class FloatingWindowView: NSVisualEffectView {
  public init(store: Store) {
    self.store = store
    super.init(frame: .zero)

    material = .menu
    blendingMode = .withinWindow

    wantsLayer = true
    layer!.cornerRadius = 6
    layer!.borderColor = NSColor.separatorColor.cgColor
    layer!.borderWidth = 1
    layer!.shadowOpacity = 0.9
    layer!.shadowRadius = 8
    layer!.shadowOffset = .init(width: 0, height: 10)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
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

  private let store: Store
  private var isToggledOn: Bool?
}
