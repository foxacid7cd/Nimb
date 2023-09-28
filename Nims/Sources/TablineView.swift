// SPDX-License-Identifier: MIT

import AppKit

final class TablineView: NSView {
  override var intrinsicContentSize: NSSize {
    .init(width: NSView.noIntrinsicMetric, height: 24)
  }

  private let store: Store

  init(store: Store) {
    self.store = store
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
