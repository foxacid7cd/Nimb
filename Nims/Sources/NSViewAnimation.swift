// SPDX-License-Identifier: MIT

import AppKit

public extension NSView {
  @discardableResult
  func animate(
    hide: Bool,
    animationDuration: Double = 0.1,
    timingFunctionName: CAMediaTimingFunctionName = .easeInEaseOut,
    completionHandler: @escaping (_ isCompleted: Bool) -> Void = { _ in }
  )
    -> Bool
  {
    if hide {
      if lastAnimatedIsHiddenValue != true {
        lastAnimatedIsHiddenValue = true
        NSAnimationContext.runAnimationGroup { context in
          context.duration = animationDuration
          context.timingFunction = .init(name: timingFunctionName)
          animator().alphaValue = 0
        } completionHandler: {
          let isCompleted = self.lastAnimatedIsHiddenValue == true
          if isCompleted {
            self.isHidden = true
          }
          completionHandler(isCompleted)
        }
        return true
      } else {
        return false
      }
    } else {
      if lastAnimatedIsHiddenValue != false {
        lastAnimatedIsHiddenValue = false
        isHidden = false
        NSAnimationContext.runAnimationGroup { context in
          context.duration = animationDuration
          context.timingFunction = .init(name: timingFunctionName)
          animator().alphaValue = 1
        } completionHandler: {
          completionHandler(self.lastAnimatedIsHiddenValue == false)
        }
        return true
      } else {
        return false
      }
    }
  }

  private static let lastAnimatedIsHiddenValueKey: Void = ()

  private var lastAnimatedIsHiddenValue: Bool? {
    get {
      withUnsafePointer(to: NSView.lastAnimatedIsHiddenValueKey) { keyPointer in
        let number = objc_getAssociatedObject(self, .init(keyPointer)) as? NSNumber
        return number?.boolValue
      }
    }
    set(value) {
      withUnsafePointer(to: NSView.lastAnimatedIsHiddenValueKey) { keyPointer in
        objc_setAssociatedObject(self, .init(keyPointer), value.map(NSNumber.init(value:)), .OBJC_ASSOCIATION_COPY)
      }
    }
  }
}
