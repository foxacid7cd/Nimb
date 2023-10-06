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

    buffersScrollView.automaticallyAdjustsContentInsets = false
    buffersScrollView.contentInsets = .init(top: 0, left: 12, bottom: 0, right: 12)
    buffersScrollView.horizontalScrollElasticity = .automatic
    buffersScrollView.verticalScrollElasticity = .none
    buffersScrollView.drawsBackground = false
    addSubview(buffersScrollView)
    buffersScrollView.leading(to: self, offset: 68)
    buffersScrollView.top(to: self)
    buffersScrollView.bottom(to: self)
    buffersScrollView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    buffersStackView.orientation = .horizontal
    buffersStackView.spacing = 16
    buffersScrollView.documentView = buffersStackView
    buffersStackView.height(to: buffersScrollView)
    buffersStackView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    buffersScrollView.width(
      to: buffersStackView,
      offset: buffersScrollView.contentInsets.left + buffersScrollView.contentInsets.right,
      priority: .init(rawValue: 200)
    )

    tabsStackView.orientation = .horizontal
    tabsStackView.spacing = 12
    addSubview(tabsStackView)
    tabsStackView.trailing(to: self, offset: -8)
    tabsStackView.top(to: self)
    tabsStackView.bottom(to: self)
    tabsStackView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    addSubview(titleTextField)
    titleTextField.centerY(to: self)
    titleTextField.leadingToTrailing(of: buffersScrollView, offset: 8)
    titleTextField.trailingToLeading(of: tabsStackView, offset: -20)
    titleTextField.setContentHuggingPriority(.init(rawValue: 100), for: .horizontal)

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

  override func layout() {
    super.layout()

    if let selectedBufferItemView {
      buffersScrollView.scrollToVisible(selectedBufferItemView.frame)
    }
  }

  func render(_ stateUpdates: State.Updates) {
    if stateUpdates.isTablineUpdated || stateUpdates.isFontUpdated {
      reloadData()
    }

    if stateUpdates.isTitleUpdated {
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = .right

      titleTextField.attributedStringValue = .init(
        string: store.title ?? "",
        attributes: [
          .foregroundColor: NSColor.textColor,
          .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
          .paragraphStyle: paragraphStyle,
        ]
      )
    }
  }

  private let store: Store
  private let visualEffectView = NSVisualEffectView()
  private let buffersScrollView = NSScrollView()
  private let buffersStackView = NSStackView(views: [])
  private var selectedBufferItemView: TablineItemView?
  private let tabsStackView = NSStackView(views: [])
  private let titleTextField = NSTextField(labelWithString: "")
  private var task: Task<Void, Never>?

  private func reloadData() {
    buffersStackView.arrangedSubviews
      .forEach { $0.removeFromSuperview() }
    selectedBufferItemView = nil

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
        let isSelected = buffer.id == store.tabline?.currentBufferID
        itemView.isSelected = isSelected
        if isSelected {
          selectedBufferItemView = itemView
        }
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
      if let selectedBufferItemView {
        buffersScrollView.scrollToVisible(selectedBufferItemView.frame)
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
