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
    layer!.shadowRadius = 5
    layer!.shadowOffset = .init(width: 4, height: -4)
    layer!.shadowOpacity = 0.3
    layer!.shadowColor = .black
    renderAppearance()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func render(_ stateUpdates: State.Updates) {
    if stateUpdates.updatedObservedHighlightNames.contains(.normalFloat) {
      renderAppearance()
    }
  }

  private let store: Store

  private func renderAppearance() {
    layer!.backgroundColor = store.state.appearance.backgroundColor(for: .normalFloat)
      .appKit
      .cgColor
    layer!.borderColor = store.state.appearance.floatingWindowBorderColor
      .appKit
      .cgColor
  }
}
