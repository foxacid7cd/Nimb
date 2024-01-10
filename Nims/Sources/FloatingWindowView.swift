// SPDX-License-Identifier: MIT

import AppKit

public class FloatingWindowView: NSView {
  public init(store: Store) {
    self.store = store
    super.init(frame: .zero)
    wantsLayer = true
    shadow = .init()
    layer!.cornerRadius = 8
    layer!.borderWidth = 1
    layer!.shadowRadius = 3
    layer!.shadowOffset = .init(width: 2, height: -2)
    layer!.shadowOpacity = 0.15
    layer!.shadowColor = .black
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public var colors: (background: Color, border: Color, highlightedBorder: Color)?
  public var isHighlighted = false

  public func render() {
    layer!.backgroundColor = colors!.background.appKit.cgColor
    let borderColor = isHighlighted ? colors!.highlightedBorder : colors!.border
    layer!.borderColor = borderColor.appKit.cgColor
  }

  private let store: Store
}
