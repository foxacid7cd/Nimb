// SPDX-License-Identifier: MIT

import AppKit

public extension NSView {
  @discardableResult
  func animate(
    hide: Bool,
    duration: Double = 0,
    timingFunctionName: CAMediaTimingFunctionName = .easeInEaseOut,
    completionHandler: @escaping (_ isCompleted: Bool) -> Void = { _ in }
  )
    -> Bool
  {
    if hide {
      if lastAnimateHide != true {
        lastAnimateHide = true
        if duration == 0 {
          alphaValue = 0
          isHidden = true
          completionHandler(true)
        } else {
          NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = .init(name: timingFunctionName)
            animator().alphaValue = 0
          } completionHandler: {
            let isCompleted = self.lastAnimateHide == true
            if isCompleted {
              self.isHidden = true
            }
            completionHandler(isCompleted)
          }
        }
        return true
      } else {
        return false
      }
    } else {
      if lastAnimateHide != false {
        lastAnimateHide = false
        isHidden = false
        if duration == 0 {
          alphaValue = 1
          completionHandler(true)
        } else {
          NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = .init(name: timingFunctionName)
            animator().alphaValue = 1
          } completionHandler: {
            completionHandler(self.lastAnimateHide == false)
          }
        }
        return true
      } else {
        return false
      }
    }
  }

  private static let lastAnimateHideKey: Void = ()

  private var lastAnimateHide: Bool? {
    get {
      withUnsafePointer(to: NSView.lastAnimateHideKey) { keyPointer in
        let number = objc_getAssociatedObject(self, .init(keyPointer)) as? NSNumber
        return number?.boolValue
      }
    }
    set(value) {
      withUnsafePointer(to: NSView.lastAnimateHideKey) { keyPointer in
        objc_setAssociatedObject(self, .init(keyPointer), value.map(NSNumber.init(value:)), .OBJC_ASSOCIATION_COPY)
      }
    }
  }
}
