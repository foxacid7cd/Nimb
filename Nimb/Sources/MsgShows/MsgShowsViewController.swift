// SPDX-License-Identifier: MIT

import AppKit
import CustomDump
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
    let view = NSView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.width(600)
    view.height(min: 360)

    scrollView.automaticallyAdjustsContentInsets = false
    scrollView.contentInsets = .init(top: 6, left: 6, bottom: 6, right: 6)
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scrollView)
    scrollView.edgesToSuperview()

    textView.isEditable = false
    textView.isSelectable = false
    textView.usesRuler = true
    textView.usesFontPanel = false
    textView.widthTracksTextView = true
    textView.heightTracksTextView = true
    scrollView.documentView = textView
    textView.textContainer.containerSize = .init(width: 600, height: 0)

    self.view = view
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    renderBackgroundColor()
  }

  public func render(_ stateUpdates: State.Updates) {
    if !stateUpdates.msgShowsUpdates.isEmpty || stateUpdates.isAppearanceUpdated {
      if !stateUpdates.updatedObservedHighlightNames.isDisjoint(with: [.normal]) {
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

      textView.setAttributedString(renderedMsgShows.map(\.1).joined(separator: .init(string: "\n")))
      textView.font = store.font.appKit()
    }
  }

  public func renderBackgroundColor() {
    let backgroundColor = store.state.appearance.defaultBackgroundColor.appKit
    scrollView.backgroundColor = backgroundColor
      .withAlphaComponent(0.6)
  }

  private static let observedHighlightName: Set<
    Appearance
      .ObservedHighlightName
  > = [
    .normalFloat,
    .special,
  ]

  private let store: Store
  private lazy var scrollView = NSScrollView()
  private lazy var textView = STTextView()
  private var renderedMsgShows = [(MsgShow, NSAttributedString)]()

  private func makeAttributedString(for msgShow: MsgShow) -> NSAttributedString {
    msgShow.contentParts
      .map { part in
        var attributes: [NSAttributedString.Key: Any] = [
          .foregroundColor: store.appearance.foregroundColor(for: part.highlightID).appKit,
        ]
        let backgroundColor = store.appearance.backgroundColor(for: part.highlightID)
        if backgroundColor != store.appearance.defaultBackgroundColor {
          attributes[.backgroundColor] = backgroundColor.appKit
        }
        return NSAttributedString(string: part.text, attributes: attributes)
      }
      .joined()
  }
}

extension Sequence where Element: NSAttributedString {
  func joined(separator: NSAttributedString? = nil) -> NSAttributedString {
    let accumulator = NSMutableAttributedString()
    var index = 0
    for attributedString in self {
      if let separator, index != 0 {
        accumulator.append(separator)
      }
      accumulator.append(attributedString)
      index += 1
    }
    return accumulator
  }
}
