// SPDX-License-Identifier: MIT

import AppKit
import Neovim
import TinyConstraints

final class TablineView: NSView {
  init(store: Store) {
    self.store = store
    super.init(frame: .zero)

    buffersStackView.orientation = .horizontal
    buffersStackView.spacing = 16
    buffersStackView.edgeInsets = .init()
    addSubview(buffersStackView)
    buffersStackView.leading(to: self, offset: 4)
    buffersStackView.top(to: self)
    buffersStackView.bottom(to: self)

    reloadData()
  }

  deinit {
    task?.cancel()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var intrinsicContentSize: NSSize {
    .init(width: NSView.noIntrinsicMetric, height: store.font.cellHeight + 4)
  }

  func render(_ stateUpdates: State.Updates) {
    if stateUpdates.isFontUpdated {
      invalidateIntrinsicContentSize()
      reloadData()

    } else if stateUpdates.isTablineUpdated {
      reloadData()
    }
  }

  private let store: Store
  private let buffersStackView = NSStackView(views: [])
  private var task: Task<Void, Never>?

  private func reloadData() {
    buffersStackView.arrangedSubviews
      .forEach { $0.removeFromSuperview() }

    let instance = store.instance

    if let tabline = store.tabline {
      for (tabpageIndex, tabpage) in tabline.tabpages.enumerated() {
        let itemView = TablineItemView(store: store)
        itemView.text = "\(tabpageIndex + 1)"
        itemView.isSelected = tabpage.id == store.tabline?.currentTabpageID
        itemView.isFirst = tabpageIndex == 0
        itemView.mouseDownObserver = {
          Task {
            await instance.reportTablineTabpageSelected(withID: tabpage.id)
          }
        }
        itemView.render()
        buffersStackView.addArrangedSubview(itemView)

        itemView.heightToSuperview()
        itemView.setContentCompressionResistancePriority(.init(800), for: .horizontal)

        if tabpageIndex < tabline.tabpages.count - 1 {
          buffersStackView.setCustomSpacing(8, after: itemView)
        }
      }

      for buffer in tabline.buffers {
        let text: String = if let match = buffer.name.firstMatch(of: /([^\/]+$)/) {
          String(match.output.1)
        } else {
          buffer.name
        }

        let itemView = TablineItemView(store: store)
        itemView.text = text
        itemView.isSelected = buffer.id == store.tabline?.currentBufferID
        itemView.isFirst = false
        itemView.mouseDownObserver = {
          Task {
            await instance.reportTablineBufferSelected(withID: buffer.id)
          }
        }
        itemView.render()
        buffersStackView.addArrangedSubview(itemView)

        itemView.heightToSuperview()
        itemView.setContentCompressionResistancePriority(.init(800), for: .horizontal)
      }
    }
  }
}
