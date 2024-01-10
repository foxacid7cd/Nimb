// SPDX-License-Identifier: MIT

import AppKit

public class FloatingWindowView: NSView {
  public init(store: Store) {
    self.store = store
    super.init(frame: .zero)
    wantsLayer = true
    layer!.cornerRadius = 8
    shadow = .init()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public var colors: (background: Color, border: Color, highlightedBorder: Color)?
  public var isHighlighted = false

  public func render() {
    layer!.backgroundColor = colors!.background.appKit.cgColor

    if isHighlighted {
      let color = colors!.highlightedBorder.appKit.cgColor
      layer!.borderColor = color
      layer!.borderWidth = 1
      layer!.shadowOffset = .zero
      layer!.shadowColor = color
      layer!.shadowOpacity = 0.15
      layer!.shadowRadius = 16
    } else {
      layer!.borderColor = colors!.border.appKit.cgColor
      layer!.borderWidth = 1
      layer!.shadowOffset = .init(width: 3, height: -3)
      layer!.shadowColor = .black
      layer!.shadowOpacity = 0.15
      layer!.shadowRadius = 2
    }
  }

  private let store: Store
}
