// SPDX-License-Identifier: MIT

import AppKit
import TinyConstraints

extension Notification: @unchecked @retroactive Sendable { }

final class TablineView: NSVisualEffectView, Rendering {
  override public var isOpaque: Bool {
    true
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

  private let store: Store
  private let buffersScrollView = NSScrollView()
  private let buffersStackView = NSStackView(views: [])
  private let buffersMaskLayer = CALayer()
  private var buffersScrollViewFrameObservation: NSKeyValueObservation?
  private let tabsScrollView = NSScrollView()
  private let tabsStackView = NSStackView(views: [])
  private let tabsMaskLayer = CALayer()
  private var tabsScrollViewFrameObservation: NSKeyValueObservation?
  private let titleTextField = NSTextField(labelWithString: "")

  private lazy var titleParagraphStyle: NSParagraphStyle = {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .right
    paragraphStyle.lineBreakMode = .byTruncatingTail
    return paragraphStyle
  }()

  init(store: Store) {
    self.store = store
    super.init(frame: .zero)

    material = .titlebar
    blendingMode = .withinWindow

    wantsLayer = true

    buffersScrollView.automaticallyAdjustsContentInsets = false
    buffersScrollView.contentInsets = .init(
      top: 0,
      left: 12,
      bottom: 0,
      right: 12
    )
    buffersScrollView.horizontalScrollElasticity = .none
    buffersScrollView.verticalScrollElasticity = .none
    buffersScrollView.drawsBackground = false
    buffersScrollView.isVerticalContentSizeConstraintActive = false
    buffersScrollView.wantsLayer = true
    buffersScrollView.layer!.mask = buffersMaskLayer
    buffersScrollViewFrameObservation = buffersScrollView
      .observe(\.frame, options: .new) { [weak self] buffersScrollView, _ in
        Task { @MainActor [self] in
          let size = buffersScrollView.frame.size
          self?.buffersMaskLayer.frame = .init(origin: .init(), size: size)
          self?.buffersMaskLayer.contents = NSImage.makeSlantedBackground(
            size: size,
            fill: .color(.black)
          )
        }
      }
    addSubview(buffersScrollView)
    buffersScrollView.leading(to: self, offset: 68)
    buffersScrollView.top(to: self)
    buffersScrollView.bottom(to: self)
    buffersScrollView.widthToSuperview(
      nil,
      multiplier: 0.5,
      relation: .equalOrLess
    )
    buffersScrollView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    buffersScrollView.setContentCompressionResistancePriority(
      .defaultHigh,
      for: .horizontal
    )

    buffersStackView.orientation = .horizontal
    buffersStackView.spacing = 14
    buffersScrollView.documentView = buffersStackView
    buffersStackView.height(to: buffersScrollView)
    buffersStackView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    buffersScrollView.width(
      to: buffersStackView,
      offset: buffersScrollView.contentInsets.left + buffersScrollView
        .contentInsets.right,
      priority: .init(rawValue: 500)
    )

    tabsScrollView.automaticallyAdjustsContentInsets = false
    tabsScrollView.contentInsets = .init(top: 0, left: 12, bottom: 0, right: 12)
    tabsScrollView.horizontalScrollElasticity = .none
    tabsScrollView.verticalScrollElasticity = .none
    tabsScrollView.drawsBackground = false
    tabsScrollView.isVerticalContentSizeConstraintActive = false
    tabsScrollView.wantsLayer = true
    tabsScrollView.layer!.mask = tabsMaskLayer
    tabsScrollViewFrameObservation = tabsScrollView
      .observe(\.frame, options: .new) { [weak self] tabsScrollView, _ in
        Task { @MainActor [self] in
          let size = tabsScrollView.frame.size
          self?.tabsMaskLayer.frame = .init(origin: .init(), size: size)
          self?.tabsMaskLayer.contents = NSImage.makeSlantedBackground(
            isFlatRight: true,
            size: size,
            fill: .color(.black)
          )
        }
      }
    addSubview(tabsScrollView)
    tabsScrollView.trailing(to: self)
    tabsScrollView.top(to: self)
    tabsScrollView.bottom(to: self)
    tabsScrollView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    tabsScrollView.widthToSuperview(
      nil,
      multiplier: 0.3,
      relation: .equalOrLess
    )

    tabsStackView.orientation = .horizontal
    tabsStackView.spacing = 14
    tabsScrollView.documentView = tabsStackView
    tabsStackView.height(to: tabsScrollView)
    tabsStackView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    tabsScrollView.width(
      to: tabsStackView,
      offset: tabsScrollView.contentInsets.left + tabsScrollView.contentInsets
        .right,
      priority: .init(rawValue: 500)
    )

    addSubview(titleTextField)
    titleTextField.centerX(to: self, priority: .init(rawValue: 100))
    titleTextField.centerY(to: self)
    titleTextField.leadingToTrailing(
      of: buffersScrollView,
      offset: 10,
      relation: .equalOrGreater
    )
    titleTextField.trailingToLeading(
      of: tabsScrollView,
      offset: -10,
      relation: .equalOrLess
    )
    titleTextField.setContentHuggingPriority(
      .init(rawValue: 100),
      for: .horizontal
    )
    titleTextField.setContentCompressionResistancePriority(
      .defaultLow,
      for: .horizontal
    )
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func mouseDown(with event: NSEvent) {
    let location = convert(event.locationInWindow, from: nil)
    if
      buffersScrollView.frame.contains(location) || tabsScrollView.frame
        .contains(location)
    {
      super.mouseDown(with: event)
    } else {
      window!.performDrag(with: event)
    }
  }

  func render() {
    guard isRendered else {
      return
    }

    if updates.isTitleUpdated || updates.isApplicationActiveUpdated {
      titleTextField.attributedStringValue = .init(
        string: state.title ?? "",
        attributes: [
          .foregroundColor: state.isApplicationActive ?
            NSColor.labelColor :
            NSColor.secondaryLabelColor,
          .font: NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .medium),
          .paragraphStyle: titleParagraphStyle,
        ]
      )
    }

    if updates.isApplicationActiveUpdated {
      titleTextField.alphaValue = state.isApplicationActive ? 0.8 : 0.7

      let sublayersOpacity: Double = state.isApplicationActive ? 1 : 0.7
      buffersScrollView.alphaValue = sublayersOpacity
      tabsScrollView.alphaValue = sublayersOpacity

      if state.isApplicationActive {
        buffersScrollView.layer!.filters = []
        tabsScrollView.layer!.filters = []
      } else {
        let monochromeFilter = CIFilter(
          name: "CIColorControls",
          parameters: [kCIInputSaturationKey: 0]
        )!
        buffersScrollView.layer!.filters = [monochromeFilter]
        tabsScrollView.layer!.filters = [monochromeFilter]
      }
    }

    if let tabline = state.tabline {
      if updates.tabline.isBuffersUpdated {
        reloadBuffers()
      } else if updates.tabline.isSelectedBufferUpdated {
        for (bufferIndex, buffer) in tabline.buffers.enumerated() {
          let itemView = buffersStackView
            .arrangedSubviews[bufferIndex] as! TablineItemView
          let isSelected = buffer.id == tabline.currentBufferID
          if isSelected != itemView.isSelected {
            itemView.isSelected = isSelected

            if itemView.isSelected {
              buffersScrollView.contentView.scrollToVisible(itemView.frame)
            }
          }

          itemView.render()
        }
      }

      if updates.tabline.isTabpagesUpdated {
        reloadTabpages()
      } else if updates.tabline.isTabpagesContentUpdated {
        for (tabpageIndex, tabpage) in tabline.tabpages.enumerated() {
          let itemView = tabsStackView
            .arrangedSubviews[tabpageIndex] as! TablineItemView
          itemView.text = "\(tabpageIndex + 1)"

          itemView.isSelected = tabpage.id == tabline.currentTabpageID
          if itemView.isSelected {
            tabsScrollView.contentView.scrollToVisible(itemView.frame)
          }

          itemView.render()
        }

      } else if updates.tabline.isSelectedTabpageUpdated {
        for (tabpageIndex, tabpage) in tabline.tabpages.enumerated() {
          let itemView = tabsStackView
            .arrangedSubviews[tabpageIndex] as! TablineItemView

          let isSelected = tabpage.id == tabline.currentTabpageID
          if isSelected != itemView.isSelected {
            itemView.isSelected = isSelected
            itemView.render()

            if itemView.isSelected {
              tabsScrollView.contentView.scrollToVisible(itemView.frame)
            }
          }
        }
      }
    }
  }

  private func reloadBuffers() {
    buffersStackView.arrangedSubviews
      .forEach { $0.removeFromSuperview() }

    guard let tabline = state.tabline else {
      return
    }

    for buffer in tabline.buffers {
      let text: String =
        if let match = buffer.name.firstMatch(of: /([^\/]+$)/) {
          String(match.output.1)
        } else {
          buffer.name
        }

      let itemView = TablineItemView(store: store)
      itemView.filledColor = .systemGreen
      itemView.text = text
      let isSelected = buffer.id == tabline.currentBufferID
      itemView.isSelected = isSelected
      if isSelected {
        var observation: NSKeyValueObservation?
        observation = itemView
          .observe(\.frame, options: .new) { [buffersScrollView] itemView, _ in
            Task { @MainActor in
              if itemView.frame.size != .zero, observation != nil {
                buffersScrollView.contentView.scrollToVisible(itemView.frame)
                observation = nil
              }
            }
          }
      }
      itemView.isLast = false
      itemView.clicked = { [store] in
        store.api.fastCall(APIFunctions.NvimSetCurrentBuf(bufferID: buffer.id))
      }
      itemView.render()
      buffersStackView.addArrangedSubview(itemView)

      itemView.heightToSuperview()
      itemView.setContentCompressionResistancePriority(
        .init(rawValue: 800),
        for: .horizontal
      )
    }
  }

  private func reloadTabpages() {
    tabsStackView.arrangedSubviews
      .forEach { $0.removeFromSuperview() }

    guard let tabline = state.tabline else {
      return
    }

    for (tabpageIndex, tabpage) in tabline.tabpages.enumerated() {
      let itemView = TablineItemView(store: store)
      itemView.filledColor = .cyan
      itemView.text = "\(tabpageIndex + 1)"
      let isSelected = tabpage.id == tabline.currentTabpageID
      itemView.isSelected = isSelected
      if isSelected {
        var observation: NSKeyValueObservation?
        observation = itemView
          .observe(\.frame, options: .new) { [tabsScrollView] itemView, _ in
            Task { @MainActor in
              if itemView.frame.size != .zero, observation != nil {
                tabsScrollView.contentView.scrollToVisible(itemView.frame)
                observation = nil
              }
            }
          }
      }
      itemView.isLast = tabpageIndex == tabline.tabpages.count - 1
      itemView.clicked = { [store] in
        store.api.fastCall(APIFunctions.NvimSetCurrentTabpage(tabpageID: tabpage.id))
      }
      itemView.render()
      tabsStackView.addArrangedSubview(itemView)

      itemView.heightToSuperview()
      itemView.setContentCompressionResistancePriority(
        .init(rawValue: 800),
        for: .horizontal
      )
    }
  }
}
