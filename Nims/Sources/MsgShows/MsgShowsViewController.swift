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
    let view = FloatingWindowView(store: store)
    view.width(max: 800)
    view.height(max: 600)
    view.alphaValue = 0
    view.isHidden = true

    scrollView.drawsBackground = false
    scrollView.scrollsDynamically = false
    scrollView.automaticallyAdjustsContentInsets = false
    view.addSubview(scrollView)
    scrollView.edgesToSuperview()

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

    renderContent()
  }

  public func render(_ stateUpdates: State.Updates) {
    (view as! FloatingWindowView).render(stateUpdates)

    if stateUpdates.isMessagesUpdated || stateUpdates.isAppearanceUpdated {
      renderContent()
      renderIsVisible()
    }
  }

  private let store: Store
  private let scrollView = NSScrollView()
  private let contentView = NSStackView(views: [])

  private func renderIsVisible() {
    (view as! FloatingWindowView).animate(
      hide: store.state.msgShows.isEmpty || store.state.isMsgShowsDismissed
    )
  }

  private func renderContent() {
    contentView.arrangedSubviews
      .forEach { $0.removeFromSuperview() }

    let layout = MsgShowsLayout(msgShows: store.state.msgShows)

    for item in layout.items {
      switch item {
      case let .texts(texts):
        for textIndex in texts.indices {
          let text = texts[textIndex]

          let textView = MsgShowTextView(store: store)
          textView.setContentHuggingPriority(.init(rawValue: 800), for: .horizontal)
          textView.setContentHuggingPriority(.init(rawValue: 800), for: .vertical)
          textView.setCompressionResistance(.init(rawValue: 900), for: .horizontal)
          textView.setCompressionResistance(.init(rawValue: 900), for: .vertical)
          textView.contentParts = text
          textView.isFirst = textIndex == texts.startIndex
          textView.isLast = textIndex == texts.index(before: texts.endIndex)
          textView.preferredMaxWidth = 640
          textView.render()
          contentView.addArrangedSubview(textView)
          textView.width(to: view)
        }

      case .separator:
        let separatorView = NSView()
        separatorView.wantsLayer = true
        separatorView.layer!.backgroundColor = store.state.appearance.floatingWindowBorderColor
          .appKit
          .cgColor
        contentView.addArrangedSubview(separatorView)
        separatorView.height(1)
        separatorView.width(to: view)
      }
    }
  }
}
