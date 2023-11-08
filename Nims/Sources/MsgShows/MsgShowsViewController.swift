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
    let view = NSView()
    view.wantsLayer = true
    view.layer!.masksToBounds = true
    view.layer!.cornerRadius = 8
    view.layer!.borderColor = NSColor.textColor.withAlphaComponent(0.2).cgColor
    view.layer!.borderWidth = 1
    view.width(max: 640)
    view.height(max: 480)
    view.alphaValue = 0

    let blurView = NSVisualEffectView()
    blurView.blendingMode = .withinWindow
    blurView.material = .popover
    view.addSubview(blurView)
    blurView.edgesToSuperview()

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
    if stateUpdates.isMsgShowsUpdated {
      renderContent()
    }
    if stateUpdates.isMsgShowsUpdated || stateUpdates.isMsgShowsDismissedUpdated {
      renderIsVisible()
    }
  }

  private let store: Store
  private let scrollView = NSScrollView()
  private let contentView = NSStackView(views: [])
  private var isVisibleAnimatedOn: Bool?

  private func renderIsVisible() {
    let shouldHide = store.state.msgShows.isEmpty || store.state.isMsgShowsDismissed

    if shouldHide {
      if isVisibleAnimatedOn != false {
        NSAnimationContext.runAnimationGroup { context in
          context.duration = 0.12
          view.animator().alphaValue = 0
        }
        isVisibleAnimatedOn = false
      }
    } else {
      if isVisibleAnimatedOn != true {
        NSAnimationContext.runAnimationGroup { context in
          context.duration = 0.12
          view.animator().alphaValue = 1
        }
        isVisibleAnimatedOn = true
      }
    }
  }

  private func renderContent() {
    contentView.arrangedSubviews
      .forEach { $0.removeFromSuperview() }

    let layout = MsgShowsLayout(store.state.msgShows)

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
        separatorView.alphaValue = 0.2
        separatorView.wantsLayer = true
        separatorView.layer!.backgroundColor = NSColor.textColor.cgColor
        contentView.addArrangedSubview(separatorView)
        separatorView.height(1)
        separatorView.width(to: view)
      }
    }
  }
}
