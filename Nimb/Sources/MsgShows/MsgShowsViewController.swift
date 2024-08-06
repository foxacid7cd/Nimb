// SPDX-License-Identifier: MIT

import AppKit
import STTextView

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
    view.width(min: 400, max: 720)
    view.height(min: 240, max: 480)

    scrollView.drawsBackground = true
    scrollView.contentInsets = .init(top: 10, left: 10, bottom: 10, right: 10)
    view.addSubview(scrollView)
    scrollView.edgesToSuperview()

    textView.isEditable = false
    textView.isSelectable = false

    self.view = view
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    renderBackgroundColor()
  }

  public func render(_ stateUpdates: State.Updates) {
    if !stateUpdates.msgShowsUpdates.isEmpty || stateUpdates.isAppearanceUpdated {
      if !stateUpdates.updatedObservedHighlightNames.isDisjoint(with: Self.observedHighlightName) {
        renderBackgroundColor()
      }

      for update in stateUpdates.msgShowsUpdates {
        switch update {
        case let .added(count):
          for index in renderedMsgShows.count ..< renderedMsgShows.count + count {
            let msgShow = store.state.msgShows[index]
            renderedMsgShows.append((msgShow, makeAttributedString(for: msgShow)))
          }

        case let .reload(indexes):
          for index in indexes {
            let msgShow = store.state.msgShows[index]
            renderedMsgShows[index] = (msgShow, makeAttributedString(for: msgShow))
          }

        case .clear:
          renderedMsgShows = []
        }
      }

      textView.setAttributedString(
        renderedMsgShows.map(\.1).joined(separator: .init(string: "\n"))
      )
    }
  }

  public func renderBackgroundColor() {
    scrollView.backgroundColor = store.state.appearance.backgroundColor(for: .normalFloat).appKit
  }

  private static let observedHighlightName: Set<
    Appearance
      .ObservedHighlightName
  > = [
    .normalFloat,
    .special,
  ]

  private let store: Store
  private lazy var customView = FloatingWindowView()
  private lazy var scrollView = STTextView.scrollableTextView()
  private lazy var textView = scrollView.documentView as! STTextView
  private var renderedMsgShows = [(MsgShow, NSAttributedString)]()

//  private func renderContent() {
//    contentView.arrangedSubviews
//      .forEach { $0.removeFromSuperview() }
//
//    let layout = MsgShowsLayout(store.state.msgShows)
//
//    for itemIndex in layout.items.indices {
//      let item = layout.items[itemIndex]
//      let isFirstItem = itemIndex == layout.items.startIndex
//      let isLastItem = itemIndex == layout.items
//        .index(before: layout.items.endIndex)
//
//      switch item {
//      case let .texts(texts):
//        for textIndex in texts.indices {
//          let text = texts[textIndex]
//          let isFirstText = textIndex == texts.startIndex
//          let isLastText = textIndex == texts.index(before: texts.endIndex)
//
//          let textView = MsgShowTextView(store: store)
//          textView.setContentHuggingPriority(
//            .init(rawValue: 800),
//            for: .horizontal
//          )
//          textView.setContentHuggingPriority(
//            .init(rawValue: 800),
//            for: .vertical
//          )
//          textView.setCompressionResistance(
//            .init(rawValue: 900),
//            for: .horizontal
//          )
//          textView.setCompressionResistance(
//            .init(rawValue: 900),
//            for: .vertical
//          )
//          textView.contentParts = text
//          textView.preferredMaxWidth = 640
//          let bigVerticalInset = max(12, store.font.cellWidth * 1.15)
//          let verticalInset = bigVerticalInset * 0.7
//          let smallVerticalInset = max(1, store.font.cellWidth * 0.15)
//          let horizontalInset = max(14, store.font.cellHeight * 0.65)
//          let topInset: Double =
//            switch (isFirstItem, isFirstText) {
//            case (true, true):
//              bigVerticalInset
//            case (false, true):
//              verticalInset
//            default:
//              smallVerticalInset
//            }
//          let bottomInset: Double =
//            switch (isLastItem, isLastText) {
//            case (true, true):
//              bigVerticalInset
//            case (false, true):
//              verticalInset
//            default:
//              smallVerticalInset
//            }
//          textView.insets = .init(
//            top: topInset,
//            left: horizontalInset,
//            bottom: bottomInset,
//            right: horizontalInset
//          )
//          textView.render()
//          contentView.addArrangedSubview(textView)
//          textView.width(to: view)
//        }
//
//      case .separator:
//        let separatorView = NSView()
//        separatorView.wantsLayer = true
//        separatorView.layer!.backgroundColor = store.state.appearance
//          .foregroundColor(for: .normalFloat)
//          .appKit
//          .withAlphaComponent(0.3)
//          .cgColor
//        contentView.addArrangedSubview(separatorView)
//        separatorView.height(1)
//        separatorView.width(to: view)
//      }
//    }
//  }

  private func makeAttributedString(for msgShow: MsgShow) -> NSAttributedString {
    .init(string: msgShow.contentParts.map(\.text).joined(), attributes: [
      .font: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .medium),
      .foregroundColor: NSColor.white,
    ])
  }
}

extension Sequence where Element: NSAttributedString {
  func joined(separator: NSAttributedString) -> NSAttributedString {
    let accumulator = NSMutableAttributedString()
    var index = 0
    for attributedString in self {
      if index != 0 {
        accumulator.append(separator)
      }
      accumulator.append(attributedString)
      index += 1
    }
    return accumulator
  }
}
