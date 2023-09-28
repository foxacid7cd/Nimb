// SPDX-License-Identifier: MIT

import AppKit
import Neovim
import TinyConstraints

final class TablineView: NSView {
  override var intrinsicContentSize: NSSize {
    .init(width: NSView.noIntrinsicMetric, height: store.font.cellHeight + 4)
  }

  private let store: Store
  private let buffersStackView = NSStackView(views: [])
  private var task: Task<Void, Never>?

  init(store: Store) {
    self.store = store
    super.init(frame: .zero)

    buffersStackView.orientation = .horizontal
    buffersStackView.spacing = 12
    buffersStackView.edgeInsets = .init()
    addSubview(buffersStackView)
    buffersStackView.leading(to: self, offset: 4)
    buffersStackView.top(to: self)
    buffersStackView.bottom(to: self)

    task = Task {
      for await stateUpdates in store.stateUpdatesStream() {
        guard !Task.isCancelled else {
          return
        }

        if stateUpdates.isFontUpdated {
          invalidateIntrinsicContentSize()
          reloadData()

        } else if stateUpdates.isTablineUpdated {
          reloadData()
        }
      }
    }
  }

  deinit {
    task?.cancel()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func reloadData() {
    buffersStackView.arrangedSubviews
      .forEach { $0.removeFromSuperview() }

    if let tabline = store.tabline {
      for (bufferIndex, buffer) in tabline.buffers.enumerated() {
        let bufferView = TablineBufferView(store: store)
        bufferView.buffer = buffer
        bufferView.index = bufferIndex
        bufferView.render()
        buffersStackView.addArrangedSubview(bufferView)
        bufferView.heightToSuperview()
        bufferView.setContentCompressionResistancePriority(.init(800), for: .horizontal)
      }
    }
  }
}
