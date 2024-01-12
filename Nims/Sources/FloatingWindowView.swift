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

  public func render() {
    layer!.backgroundColor = colors.background.appKit.cgColor
    layer!.borderColor = colors.border.appKit.cgColor
  }

  private let store: Store
}
