// SPDX-License-Identifier: MIT

import AppKit
import Neovim
import TinyConstraints

final class TablineView: NSView {
  init(store: Store) {
    self.store = store
    super.init(frame: .zero)

    visualEffectView.blendingMode = .behindWindow
    visualEffectView.material = .titlebar
    addSubview(visualEffectView)
    visualEffectView.edgesToSuperview()

    buffersStackView.orientation = .horizontal
    buffersStackView.spacing = 16
    addSubview(buffersStackView)
    buffersStackView.leading(to: self, offset: 80)
    buffersStackView.top(to: self)
    buffersStackView.bottom(to: self)

    tabsStackView.orientation = .horizontal
    tabsStackView.spacing = 12
    addSubview(tabsStackView)
    tabsStackView.trailing(to: self, offset: -8)
    tabsStackView.top(to: self)
    tabsStackView.bottom(to: self)

    addSubview(titleTextField)
    titleTextField.centerY(to: self)
    titleTextField.trailingToLeading(of: tabsStackView, offset: -20)

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
    .init(width: NSView.noIntrinsicMetric, height: preferredViewHeight)
  }

  var preferredViewHeight: CGFloat = 0 {
    didSet {
      if preferredViewHeight != oldValue {
        invalidateIntrinsicContentSize()
      }
    }
  }

  func render(_ stateUpdates: State.Updates) {
    if stateUpdates.isTablineUpdated || stateUpdates.isFontUpdated {
      reloadData()
    }

    if stateUpdates.isTitleUpdated {
      titleTextField.attributedStringValue = .init(
        string: store.title ?? "",
        attributes: [
          .foregroundColor: NSColor.textColor,
          .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
        ]
      )
    }
  }

  private let store: Store
  private let visualEffectView = NSVisualEffectView()
  private let buffersStackView = NSStackView(views: [])
  private let tabsStackView = NSStackView(views: [])
  private let titleTextField = NSTextField(labelWithString: "")
  private var task: Task<Void, Never>?

  private func reloadData() {
    buffersStackView.arrangedSubviews
      .forEach { $0.removeFromSuperview() }
    tabsStackView.arrangedSubviews
      .forEach { $0.removeFromSuperview() }

    let instance = store.instance

    if let tabline = store.tabline {
      for buffer in tabline.buffers {
        let text: String = if let match = buffer.name.firstMatch(of: /([^\/]+$)/) {
          String(match.output.1)
        } else {
          buffer.name
        }

        let itemView = TablineItemView(store: store)
        itemView.text = text
        itemView.isSelected = buffer.id == store.tabline?.currentBufferID
        itemView.isLast = false
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

      for (tabpageIndex, tabpage) in tabline.tabpages.enumerated() {
        let itemView = TablineItemView(store: store)
        itemView.text = "\(tabpageIndex + 1)"
        itemView.isSelected = tabpage.id == tabline.currentTabpageID
        itemView.isLast = tabpageIndex == tabline.tabpages.count - 1
        itemView.mouseDownObserver = {
          Task {
            await instance.reportTablineTabpageSelected(withID: tabpage.id)
          }
        }
        itemView.render()
        tabsStackView.addArrangedSubview(itemView)

        itemView.heightToSuperview()
        itemView.setContentCompressionResistancePriority(.init(800), for: .horizontal)
      }
    }
  }
}
