// SPDX-License-Identifier: MIT

import AppKit
import Library
import SwiftUI
import TinyConstraints

public class MsgShowsWindowController: NSWindowController {
  public init(store: Store, parentWindow: NSWindow) {
    self.store = store
    self.parentWindow = parentWindow

    viewController = MsgShowsViewController(store: store)

    let window = FloatingPanel(contentViewController: viewController)
    super.init(window: window)

    window.delegate = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func render(_ stateUpdates: State.Updates) {
    viewController.render(stateUpdates)

    if stateUpdates.isOuterGridLayoutUpdated || stateUpdates.isMsgShowsUpdated || stateUpdates.isMsgShowsDismissedUpdated {
      updateWindowFrameOrigin()
    }

    if stateUpdates.isMsgShowsUpdated || stateUpdates.isMsgShowsDismissedUpdated {
      if store.state.msgShows.isEmpty || store.state.isMsgShowsDismissed {
        if isVisibleAnimatedOn != false {
          NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            window!.animator().alphaValue = 0
          }
          isVisibleAnimatedOn = false
        }
      } else {
        if isVisibleAnimatedOn != true {
          if window!.parent == nil {
            parentWindow.addChildWindow(window!, ordered: .above)
            window!.alphaValue = 0
          }

          NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            window!.animator().alphaValue = 1
          }
          isVisibleAnimatedOn = true
        }
      }
    }
  }

  private let store: Store
  private let parentWindow: NSWindow
  private let viewController: MsgShowsViewController
  private var isVisibleAnimatedOn: Bool?

  private var preferredWindowOrigin: CGPoint {
    let offset = max(3, store.font.cellHeight * 0.5)
    return .init(
      x: parentWindow.frame.origin.x + offset,
      y: parentWindow.frame.origin.y + offset
    )
  }

  private func updateWindowFrameOrigin() {
    window!.setFrameOrigin(preferredWindowOrigin)
  }
}

extension MsgShowsWindowController: NSWindowDelegate {
  public func windowDidResize(_: Notification) {
    updateWindowFrameOrigin()
  }
}

public final class MsgShowsViewController: NSViewController {
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
    view.width(max: 640)
    view.height(max: 480)

    let blurView = NSVisualEffectView()
    blurView.blendingMode = .behindWindow
    blurView.state = .active
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

    reloadData()
  }

  func render(_ stateUpdates: State.Updates) {
    if stateUpdates.isMsgShowsUpdated || stateUpdates.isMsgShowsDismissedUpdated {
      reloadData()
    }
  }

  private let store: Store
  private let scrollView = NSScrollView()
  private let contentView = NSStackView(views: [])

  private func reloadData() {
    contentView.arrangedSubviews
      .forEach { $0.removeFromSuperview() }

    let layout = Layout(msgShows: store.state.msgShows)

    for item in layout.items {
      switch item {
      case let .texts(texts):
        for textIndex in texts.indices {
          let text = texts[textIndex]

          let msgShowView = TextView(store: store)
          msgShowView.contentParts = text
          msgShowView.isFirst = textIndex == texts.startIndex
          msgShowView.isLast = textIndex == texts.index(before: texts.endIndex)
          msgShowView.preferredMaxWidth = 640
          msgShowView.render()
          contentView.addArrangedSubview(msgShowView)
          msgShowView.width(to: view)
          msgShowView.setContentHuggingPriority(.init(rawValue: 800), for: .horizontal)
          msgShowView.setContentHuggingPriority(.init(rawValue: 800), for: .vertical)
          msgShowView.setCompressionResistance(.init(rawValue: 900), for: .horizontal)
          msgShowView.setCompressionResistance(.init(rawValue: 900), for: .vertical)
        }

      case .separator:
        let separatorView = NSView()
        separatorView.alphaValue = 0.15
        separatorView.wantsLayer = true
        separatorView.layer!.backgroundColor = NSColor.textColor.cgColor
        contentView.addArrangedSubview(separatorView)
        separatorView.height(1)
        separatorView.width(to: view)
      }
    }
  }
}

private final class TextView: NSView {
  init(store: Store) {
    self.store = store
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var contentParts = [MsgShow.ContentPart]()
  var preferredMaxWidth: Double = 0
  var isFirst = false
  var isLast = false

  override var intrinsicContentSize: NSSize {
    .init(
      width: boundingSize.width + insets.left + insets.right,
      height: boundingSize.height + insets.top + insets.bottom
    )
  }

  func render() {
    let bigVerticalInset = max(5, store.font.cellHeight * 0.75)
    let smallVerticalInset = max(1, store.font.cellHeight * 0.15)
    let horizontalInset = bigVerticalInset
    insets = .init(
      top: isFirst ? bigVerticalInset : smallVerticalInset,
      left: horizontalInset,
      bottom: isLast ? bigVerticalInset : smallVerticalInset,
      right: horizontalInset
    )

    let attributedString = NSMutableAttributedString()

    for contentPart in contentParts {
      var attributes: [NSAttributedString.Key: Any] = [
        .font: store.font.nsFont(),
        .foregroundColor: store.appearance.foregroundColor(for: contentPart.highlightID).appKit,
      ]

      let backgroundColor = store.appearance.backgroundColor(for: contentPart.highlightID)
      if backgroundColor != store.appearance.defaultBackgroundColor {
        attributes[.backgroundColor] = store.appearance.backgroundColor(for: contentPart.highlightID).appKit
          .withAlphaComponent(0.6)
      }

      attributedString.append(.init(
        string: contentPart.text,
        attributes: attributes
      ))
    }

    let stringRange = CFRange(location: 0, length: attributedString.length)
    let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
    let containerSize = CGSize(width: preferredMaxWidth - (insets.left + insets.right), height: .greatestFiniteMagnitude)
    boundingSize = CTFramesetterSuggestFrameSizeWithConstraints(
      framesetter,
      stringRange,
      nil,
      containerSize,
      nil
    )
    invalidateIntrinsicContentSize()

    ctFrame = CTFramesetterCreateFrame(
      framesetter,
      stringRange,
      CGPath(
        rect: .init(
          origin: .init(x: insets.left, y: insets.bottom),
          size: .init(
            width: containerSize.width,
            height: ceil(boundingSize.height)
          )
        ),
        transform: nil
      ),
      nil
    )
    setNeedsDisplay(bounds)
  }

  override func draw(_: NSRect) {
    guard let ctFrame else {
      return
    }

    let graphicsContext = NSGraphicsContext.current!
    let cgContext = graphicsContext.cgContext

    CTFrameDraw(ctFrame, cgContext)
  }

  private let store: Store
  private var boundingSize = CGSize()
  private var ctFrame: CTFrame?
  private var insets = NSEdgeInsets()
}

private struct Layout: Sendable {
  init(msgShows: [MsgShow]) {
    var items = [Item]()

    var accumulator = [[MsgShow.ContentPart]]()
    func finishTextsItem() {
      guard !accumulator.isEmpty else {
        return
      }
      items.append(.texts(accumulator))
      accumulator.removeAll(keepingCapacity: true)
    }

    for index in msgShows.indices {
      let msgShow = msgShows[index]
      let isLast = index == msgShows.index(before: msgShows.endIndex)

      if isLast, MsgShow.Kind.modal.contains(msgShow.kind) {
        finishTextsItem()
        items.append(.separator)
      }

      var text = [MsgShow.ContentPart]()
      for var contentPart in msgShow.contentParts {
        contentPart.text = contentPart.text
          .trimmingCharacters(in: .newlines)

        if !contentPart.text.isEmpty {
          text.append(contentPart)
        }
      }
      if !text.isEmpty {
        accumulator.append(text)
      }
    }
    finishTextsItem()

    self.items = items
  }

  enum Item: Sendable {
    case texts([[MsgShow.ContentPart]])
    case separator
  }

  var items: [Item]
}
