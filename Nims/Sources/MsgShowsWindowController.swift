// SPDX-License-Identifier: MIT

import AppKit
import Library
import SwiftUI
import TinyConstraints

final class MsgShowsWindowController: NSWindowController {
  init(store: Store, parentWindow: NSWindow) {
    self.store = store
    self.parentWindow = parentWindow

    viewController = MsgShowsViewController(store: store)

    let window = NimsNSWindow(contentViewController: viewController)
    window._canBecomeKey = false
    window._canBecomeMain = false
    window.styleMask = [.titled, .fullSizeContentView]
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.isOpaque = false
    window.isMovable = false
    window.setIsVisible(false)

    super.init(window: window)

    window.delegate = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func render(_ stateUpdates: State.Updates) {
    viewController.render(stateUpdates)

    if stateUpdates.isOuterGridLayoutUpdated || stateUpdates.isMsgShowsUpdated {
      updateWindowOrigin()
    }

    if stateUpdates.isMsgShowsUpdated || stateUpdates.isMsgShowsDismissedUpdated {
      if window!.isVisible {
        if store.state.msgShows.isEmpty || store.state.isMsgShowsDismissed {
          parentWindow.removeChildWindow(window!)
          window!.setIsVisible(false)
        }

      } else {
        if !store.state.msgShows.isEmpty, !store.state.isMsgShowsDismissed {
          parentWindow.addChildWindow(window!, ordered: .above)
        }
      }
    }
  }

  private let store: Store
  private let parentWindow: NSWindow
  private let viewController: MsgShowsViewController

  private func updateWindowOrigin() {
    window!.setFrameOrigin(.init(
      x: parentWindow.frame.origin.x + 10,
      y: parentWindow.frame.origin.y + 10
    ))
  }
}

extension MsgShowsWindowController: NSWindowDelegate {
  func windowDidResize(_: Notification) {
    updateWindowOrigin()
  }
}

final class MsgShowsViewController: NSViewController {
  init(store: Store) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
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

  override func viewDidLoad() {
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

    let msgShows = store.state.msgShows

    for (index, msgShow) in msgShows.enumerated() {
      let msgShowView = TextView(store: store)
      msgShowView.msgShow = msgShow
      msgShowView.preferredMaxWidth = 640
      msgShowView.render()
      contentView.addArrangedSubview(msgShowView)
      msgShowView.width(to: view)
      msgShowView.setContentHuggingPriority(.init(rawValue: 800), for: .horizontal)
      msgShowView.setContentHuggingPriority(.init(rawValue: 800), for: .vertical)
      msgShowView.setCompressionResistance(.init(rawValue: 900), for: .horizontal)
      msgShowView.setCompressionResistance(.init(rawValue: 900), for: .vertical)

      if index < msgShows.count - 1 {
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

  var msgShow: MsgShow?
  var preferredMaxWidth: Double = 0

  override var intrinsicContentSize: NSSize {
    .init(
      width: boundingSize.width + 20,
      height: boundingSize.height + 20
    )
  }

  func render() {
    guard let msgShow else {
      return
    }

    let attributedString = NSMutableAttributedString()

    for contentPart in msgShow.contentParts {
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
    let containerSize = CGSize(width: preferredMaxWidth - 20, height: .greatestFiniteMagnitude)
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
          origin: .init(x: 10, y: 10),
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
}
