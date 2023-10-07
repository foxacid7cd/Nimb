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
    buffersScrollView.isVerticalContentSizeConstraintActive = false
    buffersScrollView.wantsLayer = true
    buffersScrollView.layer!.mask = buffersMaskLayer
    addSubview(buffersScrollView)
    buffersScrollView.leading(to: self, offset: 68)
    buffersScrollView.top(to: self)
    buffersScrollView.bottom(to: self)
    buffersScrollView.widthToSuperview(nil, multiplier: 0.5, relation: .equal)
    buffersScrollView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    buffersStackView.orientation = .horizontal
    buffersStackView.spacing = 16
    buffersScrollView.documentView = buffersStackView
    buffersStackView.height(to: buffersScrollView)
    buffersStackView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    tabsStackView.orientation = .horizontal
    tabsStackView.spacing = 12
    addSubview(tabsStackView)
    tabsStackView.trailing(to: self, offset: -8)
    tabsStackView.top(to: self)
    tabsStackView.bottom(to: self)
    tabsStackView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    addSubview(titleTextField)
    titleTextField.centerY(to: self)
    titleTextField.leadingToTrailing(of: buffersScrollView, offset: 10)
    titleTextField.trailingToLeading(of: tabsStackView, offset: -22)
    titleTextField.setContentHuggingPriority(.init(rawValue: 100), for: .horizontal)
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
    guard let tabline = store.tabline else {
      return
    }

    if stateUpdates.tabline.isBuffersUpdated {
      reloadBuffers()
    } else if stateUpdates.tabline.isSelectedBufferUpdated {
      for (bufferIndex, buffer) in tabline.buffers.enumerated() {
        let itemView = buffersStackView.arrangedSubviews[bufferIndex] as! TablineItemView

        let isSelected = buffer.id == tabline.currentBufferID
        if isSelected != itemView.isSelected {
          itemView.isSelected = isSelected
          itemView.render()

          if itemView.isSelected {
            selectedBufferItemView = itemView
          }
        }
      }
    }

    if stateUpdates.tabline.isTabpagesUpdated {
      reloadTabpages()
    } else if stateUpdates.tabline.isTabpagesContentUpdated {
      for (tabpageIndex, tabpage) in tabline.tabpages.enumerated() {
        let itemView = tabsStackView.arrangedSubviews[tabpageIndex] as! TablineItemView
        itemView.text = "\(tabpageIndex + 1)"
        itemView.isSelected = tabpage.id == tabline.currentTabpageID
        itemView.render()
      }

    } else if stateUpdates.tabline.isSelectedTabpageUpdated {
      for (tabpageIndex, tabpage) in tabline.tabpages.enumerated() {
        let itemView = tabsStackView.arrangedSubviews[tabpageIndex] as! TablineItemView

        let isSelected = tabpage.id == tabline.currentTabpageID
        if isSelected != itemView.isSelected {
          itemView.isSelected = isSelected
          itemView.render()
        }
      }
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

    if stateUpdates.tabline.isSelectedBufferUpdated, let selectedBufferItemView {
      if selectedBufferItemView.frame.size != .zero {
        buffersScrollView.contentView.scrollToVisible(selectedBufferItemView.frame)
      } else {
        var observation: NSKeyValueObservation?
        observation = selectedBufferItemView.observe(\.frame, options: .new) { itemView, _ in
          Task { @MainActor in
            if itemView.frame.size != .zero, observation != nil {
              self.buffersScrollView.contentView.scrollToVisible(itemView.frame)
              observation?.invalidate()
              observation = nil
            }
          }
        }
      }
    }
  }

  func updateBuffersMask() {
    let size = CGSize(width: buffersScrollView.frame.width, height: buffersScrollView.frame.height)
    buffersMaskLayer.frame = .init(origin: .init(), size: size)
    buffersMaskLayer.contents = NSImage.makeSlantedBackground(type: .mask, size: size, color: .black)
  }

  private let store: Store
  private let visualEffectView = NSVisualEffectView()
  private let buffersScrollView = NSScrollView()
  private let buffersStackView = NSStackView(views: [])
  private var selectedBufferItemView: TablineItemView?
  private let tabsStackView = NSStackView(views: [])
  private let titleTextField = NSTextField(labelWithString: "")
  private let buffersMaskLayer = CALayer()

  private func reloadBuffers() {
    buffersStackView.arrangedSubviews
      .forEach { $0.removeFromSuperview() }
    selectedBufferItemView = nil

    let instance = store.instance

    guard let tabline = store.tabline else {
      return
    }

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
      itemView.setContentCompressionResistancePriority(.init(rawValue: 800), for: .horizontal)
    }
  }

  private func reloadTabpages() {
    tabsStackView.arrangedSubviews
      .forEach { $0.removeFromSuperview() }

    let instance = store.instance

    guard let tabline = store.tabline else {
      return
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
      itemView.setContentCompressionResistancePriority(.init(rawValue: 800), for: .horizontal)
    }
  }
}
