// SPDX-License-Identifier: MIT

import AppKit

public class FloatingWindowView: NSView {
  public init(store: Store) {
    self.store = store
    super.init(frame: .zero)
    shadow = .init()
    wantsLayer = true
    layer!.cornerRadius = 8
    layer!.borderWidth = 1
    layer!.shadowOffset = .init(width: 3, height: -3)
    layer!.shadowColor = .black
    layer!.shadowOpacity = 0.15
    layer!.shadowRadius = 2
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public var colors: (background: Color, border: Color) = (.black, .black)
  public var animatingToggling: ((_ on: Bool, _ animationDuration: Double) -> Void)?

  public func render() {
    layer!.backgroundColor = colors.background.appKit.cgColor
    layer!.borderColor = colors.border.appKit.cgColor
  }

  @discardableResult
  public func toggle(on: Bool, animationDuration: Double = 0) -> Bool {
    if on {
      if isToggledOn != true {
        isToggledOn = true
        isHidden = false
        if animationDuration == 0 {
          alphaValue = 1
          animatingToggling?(on, animationDuration)
        } else {
          NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            context.timingFunction = .init(name: on ? .easeOut : .easeIn)
            animator().alphaValue = 1
            animatingToggling?(on, animationDuration)
          }
        }
        return true
      }
    } else {
      if isToggledOn != false {
        isToggledOn = false
        if animationDuration == 0 {
          alphaValue = 0
          animatingToggling?(on, animationDuration)
          isHidden = true
        } else {
          NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            animator().alphaValue = 0
            animatingToggling?(on, animationDuration)
          } completionHandler: {
            if self.isToggledOn == false {
              self.isHidden = true
            }
          }
        }
        return true
      }
    }
    return false
  }

  private let store: Store
  private var isToggledOn: Bool?
}
