// SPDX-License-Identifier: MIT

import AppKit

public class MsgShowsViewController: NSViewController {
  public init(store: Store) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func loadView() {
    let view = customView
    view.width(max: 800)
    view.height(max: 600)
    view.layer!.cornerRadius = 14
    view.layer!.maskedCorners = [.layerMaxXMaxYCorner]

    scrollView.drawsBackground = false
    scrollView.scrollsDynamically = false
    scrollView.automaticallyAdjustsContentInsets = false
    view.addSubview(scrollView)
    scrollView.leading(to: view)
    scrollView.trailing(to: view)
    scrollView.topToSuperview()
    scrollView.bottomToSuperview(offset: 1)

    contentView.setContentHuggingPriority(.init(rawValue: 900), for: .vertical)
    contentView.setContentHuggingPriority(.init(rawValue: 900), for: .horizontal)
    contentView.orientation = .vertical
    contentView.edgeInsets = .init()
    contentView.spacing = 0
    contentView.distribution = .fill
    scrollView.documentView = contentView

    scrollView.size(to: contentView, priority: .init(rawValue: 800))

    self.view = view
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    customView.toggle(on: false)
    renderCustomView()
    renderContent()
  }

  public func render(_ stateUpdates: State.Updates) {
    if 
      stateUpdates.isAppearanceUpdated,
      stateUpdates.updatedObservedHighlightNames
        .contains(where: MsgShowsViewController.observedHighlightName.contains(_:))
    {
      renderCustomView()
    }

    if stateUpdates.isMessagesUpdated || stateUpdates.isAppearanceUpdated {
      if !store.state.msgShows.isEmpty {
        renderContent()
      }
    }

    if stateUpdates.isMessagesUpdated {
      customView.toggle(
        on: !store.state.msgShows.isEmpty && !store.state.isMsgShowsDismissed
      )
    }
  }

  private static let observedHighlightName: Set<Appearance.ObservedHighlightName> = [
    .normalFloat,
    .special,
  ]

  private let store: Store
  private lazy var customView = FloatingWindowView(store: store)
  private lazy var scrollView = NSScrollView()
  private lazy var contentView = NSStackView(views: [])

  private func renderCustomView() {
    customView.colors = (
      background: store.appearance.backgroundColor(for: .normalFloat),
      border: store.appearance.foregroundColor(for: .normalFloat)
        .with(alpha: 0.3)
    )
    customView.render()
  }

  private func renderContent() {
    contentView.arrangedSubviews
      .forEach { $0.removeFromSuperview() }

    let layout = MsgShowsLayout(store.state.msgShows)

    for itemIndex in layout.items.indices {
      let item = layout.items[itemIndex]
      let isFirstItem = itemIndex == layout.items.startIndex
      let isLastItem = itemIndex == layout.items.index(before: layout.items.endIndex)

      switch item {
      case let .texts(texts):
        for textIndex in texts.indices {
          let text = texts[textIndex]
          let isFirstText = textIndex == texts.startIndex
          let isLastText = textIndex == texts.index(before: texts.endIndex)

          let textView = MsgShowTextView(store: store)
          textView.setContentHuggingPriority(.init(rawValue: 800), for: .horizontal)
          textView.setContentHuggingPriority(.init(rawValue: 800), for: .vertical)
          textView.setCompressionResistance(.init(rawValue: 900), for: .horizontal)
          textView.setCompressionResistance(.init(rawValue: 900), for: .vertical)
          textView.contentParts = text
          textView.preferredMaxWidth = 640
          let bigVerticalInset = max(12, store.font.cellWidth * 1.15)
          let verticalInset = bigVerticalInset * 0.7
          let smallVerticalInset = max(1, store.font.cellWidth * 0.15)
          let horizontalInset = max(14, store.font.cellHeight * 0.65)
          let topInset: Double =
            switch (isFirstItem, isFirstText) {
            case (true, true):
              bigVerticalInset
            case (false, true):
              verticalInset
            default:
              smallVerticalInset
            }
          let bottomInset: Double =
            switch (isLastItem, isLastText) {
            case (true, true):
              bigVerticalInset
            case (false, true):
              verticalInset
            default:
              smallVerticalInset
            }
          textView.insets = .init(
            top: topInset,
            left: horizontalInset,
            bottom: bottomInset,
            right: horizontalInset
          )
          textView.render()
          contentView.addArrangedSubview(textView)
          textView.width(to: view)
        }

      case .separator:
        let separatorView = NSView()
        separatorView.wantsLayer = true
        separatorView.layer!.backgroundColor = store.state.appearance
          .foregroundColor(for: .normalFloat)
          .appKit
          .withAlphaComponent(0.3)
          .cgColor
        contentView.addArrangedSubview(separatorView)
        separatorView.height(1)
        separatorView.width(to: view)
      }
    }
  }
}
