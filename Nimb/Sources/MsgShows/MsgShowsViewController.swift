// SPDX-License-Identifier: MIT

import AppKit
import NimbState

public class MsgShowsViewController: NSViewController, Rendering {
  public var renderContext: RenderContext! = nil

  private let store: Store
  private lazy var scrollView = NSScrollView()
  private lazy var textView = NSTextView()
  private var renderedMsgShows = [(MsgShow, NSAttributedString)]()

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
    textView.usesFontPanel = false
    textView.allowsUndo = false

    // The panel behind this is translucent, and NSTextView would otherwise fill
    // itself with an opaque textBackgroundColor.
    textView.drawsBackground = false

    // STTextView insets by nothing; NSTextView defaults to a 5pt line fragment
    // padding, which would shift the text right.
    textView.textContainerInset = .zero
    textView.textContainer?.lineFragmentPadding = 0

    // documentView of an NSScrollView is driven by autoresizing, not
    // constraints: width tracks the scroll view, height grows with content.
    textView.translatesAutoresizingMaskIntoConstraints = true
    textView.autoresizingMask = [.width]
    textView.minSize = .zero
    textView.maxSize = .init(
      width: CGFloat.greatestFiniteMagnitude,
      height: CGFloat.greatestFiniteMagnitude,
    )
    textView.isVerticallyResizable = true
    textView.isHorizontallyResizable = false
    textView.textContainer?.widthTracksTextView = true
    textView.textContainer?.heightTracksTextView = false
    textView.textContainer?.size = .init(
      width: 0,
      height: CGFloat.greatestFiniteMagnitude,
    )

    scrollView.documentView = textView

    self.view = view
  }

  public func render() {
    if updates.isMsgHistoryUpdated || (updates.isAppearanceUpdated && !state.msgHistory.isEmpty) {
      renderedMsgShows = state.msgHistory
        .map { ($0, makeAttributedString(for: $0)) }
      renderText()
      return
    }
    guard state.msgHistory.isEmpty else {
      return
    }

    if updates.isAppearanceUpdated {
      renderBackgroundColor()

      renderedMsgShows = state.msgShows
        .map { ($0, makeAttributedString(for: $0)) }

      renderText()
    } else if !updates.msgShowsUpdates.isEmpty {
      if updates.msgShowsUpdates.count > 1 {
        renderedMsgShows = state.msgShows
          .map { ($0, makeAttributedString(for: $0)) }
      } else {
        for update in updates.msgShowsUpdates {
          switch update {
          case let .added(count):
            for index in renderedMsgShows.count ..< renderedMsgShows.count + count {
              let msgShow = state.msgShows[index]

              renderedMsgShows.append((msgShow, makeAttributedString(for: msgShow)))
            }

          case let .reload(indexes):
            for index in indexes {
              let msgShow = state.msgShows[index]
              renderedMsgShows[index] = (msgShow, makeAttributedString(for: msgShow))
            }

          case .clear:
            renderedMsgShows.removeAll(keepingCapacity: true)
          }
        }
      }

      renderText()
    }
  }

  public func renderBackgroundColor() {
    let backgroundColor = state.appearance.defaultBackgroundColor.appKit
    scrollView.backgroundColor = backgroundColor
      .withAlphaComponent(0.8)
  }

  public func renderText() {
    let attributedString = renderedMsgShows.map(\.1)
      .joined(separator: .init(string: "\n"))
    textView.textStorage?.setAttributedString(attributedString)
  }

  private func makeAttributedString(for msgShow: MsgShow) -> NSAttributedString {
    zip(
      0 ..< msgShow.contentParts.count,
      msgShow.contentParts,
    )
    .map { index, part in
      var attributes: [NSAttributedString.Key: Any] = [
        .font: state.font.appKit(
          isBold: state.appearance.isBold(for: part.highlightID),
          isItalic: state.appearance.isItalic(for: part.highlightID),
        ),
        .foregroundColor: state.appearance.foregroundColor(for: part.highlightID).appKit,
      ]
      let backgroundColor = state.appearance.backgroundColor(for: part.highlightID)
      if backgroundColor != state.appearance.defaultBackgroundColor {
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
