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
    view.height(min: 400)

    scrollView.drawsBackground = true
    scrollView.automaticallyAdjustsContentInsets = false
    scrollView.contentInsets = .init(top: 2, left: 0, bottom: 2, right: 0)
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scrollView)
    scrollView.edgesToSuperview()

    textView.isEditable = false
    textView.isSelectable = true
    textView.usesRuler = false
    textView.usesFontPanel = false
    textView.widthTracksTextView = true
    textView.heightTracksTextView = true
    textView.isHorizontalContentSizeConstraintActive = true
    scrollView.documentView = textView

    self.view = view
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    renderBackgroundColor()
  }

  public func render(_ stateUpdates: State.Updates) {
    if stateUpdates.isAppearanceUpdated {
      renderBackgroundColor()

      renderedMsgShows.removeAll(keepingCapacity: true)
      renderedMsgShows = store.state.msgShows
        .map { ($0, makeAttributedString(for: $0)) }

      renderText()
    } else if !stateUpdates.msgShowsUpdates.isEmpty {
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
          renderedMsgShows.removeAll(keepingCapacity: true)
        }
      }

      renderText()
    }
  }

  public func renderBackgroundColor() {
    let backgroundColor = store.state.appearance.defaultBackgroundColor.appKit
    scrollView.backgroundColor = backgroundColor
      .withAlphaComponent(0.8)
  }

  public func renderText() {
    textView.setAttributedString(renderedMsgShows.map(\.1).joined(separator: .init(string: "\n")))
  }

  private let store: Store
  private lazy var scrollView = NSScrollView()
  private lazy var textView = STTextView()
  private var renderedMsgShows = [(MsgShow, NSAttributedString)]()

  private func makeAttributedString(for msgShow: MsgShow) -> NSAttributedString {
    zip(
      0 ..< msgShow.contentParts.count,
      msgShow.contentParts
    )
    .map { index, part in
      var attributes: [NSAttributedString.Key: Any] = [
        .font: store.font.appKit(
          isBold: store.appearance.isBold(for: part.highlightID),
          isItalic: store.appearance.isItalic(for: part.highlightID)
        ),
        .foregroundColor: store.appearance.foregroundColor(for: part.highlightID).appKit,
      ]
      let backgroundColor = store.appearance.backgroundColor(for: part.highlightID)
      if backgroundColor != store.appearance.defaultBackgroundColor {
        attributes[.backgroundColor] = backgroundColor.appKit
      }
      let text = index == 0 ?
        String(part.text.trimmingPrefix(while: { $0 == "\n" || $0 == "\r" })) : part.text
      return NSAttributedString(string: text, attributes: attributes)
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
