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
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public var colors: (background: Color, border: Color) = (.black, .black)
  public var isHighlighted = false
  public var shouldHide = true

  public func render() {
    layer!.backgroundColor = colors.background.appKit.cgColor
    layer!.borderColor = colors.border.appKit.cgColor

    if !isHighlighted || unhighlighTask == nil {
      unhighlighTask = nil

      render(isHighlighted: isHighlighted)
    }

    animate(hide: shouldHide, animationDuration: shouldHide ? 0.1 : 0.01) { isCompleted in
      if self.isHighlighted {
        if isCompleted, self.unhighlighTask == nil {
          self.unhighlighTask = Task {
            await NSAnimationContext.runAnimationGroup { context in
              context.duration = 0.12
              context.allowsImplicitAnimation = true
              render(isHighlighted: false)
            }
          }
        }
      }
    }

    func render(isHighlighted: Bool) {
      if isHighlighted {
        layer!.shadowOffset = .zero
        layer!.shadowColor = .white
        layer!.shadowOpacity = 0.05
        layer!.shadowRadius = 8
      } else {
        layer!.shadowOffset = .init(width: 3, height: -3)
        layer!.shadowColor = .black
        layer!.shadowOpacity = 0.15
        layer!.shadowRadius = 2
      }
    }
  }

  private let store: Store
  private var unhighlighTask: Task<Void, any Error>?
}
