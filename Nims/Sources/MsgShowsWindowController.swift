// SPDX-License-Identifier: MIT

import AppKit
import Library
import Neovim
import SwiftUI
import TinyConstraints

class MsgShowsWindowController: NSWindowController {
  private let store: Store
  private let parentWindow: NSWindow
  private let viewController: MsgShowsViewController
  private var task: Task<Void, Never>?

  init(store: Store, parentWindow: NSWindow) {
    self.store = store
    self.parentWindow = parentWindow

    viewController = MsgShowsViewController(store: store)

    let window = NSWindow(contentViewController: viewController)
    window.styleMask = [.titled, .fullSizeContentView, .resizable]
    window.title = "Messages"
    window.isOpaque = false
    window.setIsVisible(false)

    super.init(window: window)

    window.delegate = self

    task = Task { [weak self] in
      for await stateUpdates in store.stateUpdatesStream() {
        guard let self, !Task.isCancelled else {
          break
        }

        if stateUpdates.isMsgShowsUpdated || stateUpdates.isAppearanceUpdated || stateUpdates.isFontUpdated {
          updateWindow()
        }
      }
    }
  }

  deinit {
    task?.cancel()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func updateWindow() {
    viewController.render()

    window!.level = store.hasModalMsgShows ? .modalPanel : .normal

    if store.msgShows.isEmpty {
      window!.setIsVisible(false)

    } else {
      window!.setIsVisible(true)
      window!.makeMain()
    }
  }
}

extension MsgShowsWindowController: NSWindowDelegate {
  func windowDidResize(_: Notification) {}
}

final class MsgShowsViewController: NSViewController {
  private let store: Store
  private let scrollView = NSScrollView()
  private let contentView = NSStackView(views: [])

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
    view.width(600)
    view.height(min: 400)

    let blurView = NSVisualEffectView()
    blurView.blendingMode = .behindWindow
    blurView.state = .active
    view.addSubview(blurView)
    blurView.edgesToSuperview()

    scrollView.drawsBackground = false
    scrollView.scrollsDynamically = false
    view.addSubview(scrollView)
    scrollView.edgesToSuperview()

    contentView.setContentHuggingPriority(.init(rawValue: 700), for: .vertical)
    contentView.setCompressionResistance(.init(rawValue: 900), for: .vertical)
    contentView.setContentHuggingPriority(.init(rawValue: 900), for: .horizontal)
    contentView.orientation = .vertical
    contentView.edgeInsets = .init()
    contentView.spacing = 0
    scrollView.documentView = contentView
    contentView.width(to: view)

    self.view = view
  }

  func render() {
    contentView.arrangedSubviews
      .forEach { $0.removeFromSuperview() }

    for (msgShowIndex, msgShow) in store.msgShows.enumerated() {
      let msgShowView = MsgShowView(store: store)
      msgShowView.msgShow = msgShow
      msgShowView.render()
      contentView.addArrangedSubview(msgShowView)
      msgShowView.width(to: view)

      if msgShowIndex < store.msgShows.count - 1 {
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

private final class MsgShowView: NSView {
  var msgShow: MsgShow?

  override var intrinsicContentSize: NSSize {
    .init(
      width: bounds.width,
      height: (boundingSize?.height ?? 0) + 20
    )
  }

  override var frame: NSRect {
    didSet {
      if frame.width != oldValue.width {
        invalidateIntrinsicContentSize()
      }
    }
  }

  private let store: Store
  private var boundingSize: CGSize?
  private var ctFrame: CTFrame?

  init(store: Store) {
    self.store = store
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layout() {
    render()
  }

  func render() {
    guard let msgShow else {
      return
    }

    let attributedString = NSMutableAttributedString()
    for contentPart in msgShow.contentParts {
      attributedString.append(.init(
        string: contentPart.text,
        attributes: [
          .font: store.font.nsFont(),
          .foregroundColor: store.appearance.foregroundColor(for: contentPart.highlightID).appKit,
        ]
      ))
    }

    let stringRange = CFRange(location: 0, length: attributedString.length)
    let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
    let containerSize = CGSize(width: bounds.width - 20, height: .greatestFiniteMagnitude)
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
            height: ceil(boundingSize!.height)
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

    cgContext.saveGState()
    defer { cgContext.restoreGState() }

    CTFrameDraw(ctFrame, graphicsContext.cgContext)
  }
}
