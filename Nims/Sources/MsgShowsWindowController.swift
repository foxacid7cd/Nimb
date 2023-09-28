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

    let window = Window(contentViewController: viewController)
    window.styleMask = [.titled, .fullSizeContentView]
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.isMovable = false
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
    let containerSize = CGSize(width: 1004, height: Double.greatestFiniteMagnitude)

    let attributedString = makeContentAttributedString(
      msgShows: store.msgShows,
      font: store.font,
      appearance: store.appearance
    )
    let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
    let boundingSize = CTFramesetterSuggestFrameSizeWithConstraints(
      framesetter,
      .init(location: 0, length: attributedString.length),
      nil,
      containerSize,
      nil
    )

    let ctFrame = CTFramesetterCreateFrame(
      framesetter,
      .init(location: 0, length: attributedString.length),
      CGPath(
        rect: .init(
          origin: .zero,
          size: .init(width: containerSize.width, height: ceil(boundingSize.height))
        ),
        transform: nil
      ),
      nil
    )
    viewController.update(contentSize: boundingSize, ctFrame: ctFrame)

    updateWindowOrigin()

    if store.msgShows.isEmpty {
      parentWindow.removeChildWindow(window!)
      window?.setIsVisible(false)
    } else {
      parentWindow.addChildWindow(window!, ordered: .above)
    }
  }

  private func updateWindowOrigin() {
    window!.setFrameOrigin(
      .init(
        x: parentWindow.frame.minX,
        y: parentWindow.frame.minY
      )
    )
  }
}

extension MsgShowsWindowController: NSWindowDelegate {
  func windowDidResize(_: Notification) {
    updateWindowOrigin()
  }
}

final class MsgShowsViewController: NSViewController {
  private let store: Store
  private let scrollView = NSScrollView()
  private let documentView = DocumentView()

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

    let blurView = NSVisualEffectView()
    blurView.blendingMode = .behindWindow
    blurView.state = .active
    view.addSubview(blurView)
    blurView.edgesToSuperview()

    scrollView.drawsBackground = false
    scrollView.scrollsDynamically = false
    scrollView.automaticallyAdjustsContentInsets = false
    scrollView.contentInsets = .init(top: 10, left: 10, bottom: 10, right: 10)
    scrollView.documentView = documentView
    view.addSubview(scrollView)

    scrollView.edgesToSuperview()
    scrollView.width(max: 1024)
    scrollView.height(max: 768)

    let scrollViewToDocumentWidthConstraint = scrollView.width(to: documentView)
    scrollViewToDocumentWidthConstraint.priority = .init(rawValue: 751)

    let scrollViewToDocumentHeightConstraint = scrollView.height(to: documentView)
    scrollViewToDocumentHeightConstraint.priority = .init(rawValue: 751)

    self.view = view
  }

  func update(contentSize: CGSize, ctFrame: CTFrame) {
    documentView.setFrameSize(contentSize)
    documentView.ctFrame = ctFrame
    documentView.needsDisplay = true
  }
}

private final class Window: NSWindow {
  override var canBecomeKey: Bool {
    false
  }

  override var canBecomeMain: Bool {
    false
  }
}

private final class DocumentView: NSView {
  var ctFrame: CTFrame?

  override func draw(_ dirtyRect: NSRect) {
    guard let ctFrame else {
      return
    }

    let graphicsContext = NSGraphicsContext.current!
    let cgContext = graphicsContext.cgContext

    cgContext.saveGState()

    dirtyRect.clip()

    CTFrameDraw(ctFrame, graphicsContext.cgContext)

    cgContext.restoreGState()
  }
}

@MainActor
private func makeContentAttributedString(msgShows: [MsgShow], font: NimsFont, appearance: Appearance) -> NSAttributedString {
  let accumulator = NSMutableAttributedString()

  for (index, msgShow) in msgShows.enumerated() {
    for contentPart in msgShow.contentParts {
      let attributedString = NSAttributedString(
        string: contentPart.text
          .trimmingCharacters(in: .whitespaces),
        attributes: [
          .font: font.nsFont(),
          .foregroundColor: appearance.foregroundColor(for: contentPart.highlightID).appKit,
        ]
      )
      accumulator.append(attributedString)
    }

    if index < msgShows.count - 1 {
      accumulator.append(.init(string: "\n"))
    }
  }

  let paragraphStyle = NSMutableParagraphStyle()
  paragraphStyle.lineBreakMode = .byWordWrapping
  accumulator.addAttribute(.paragraphStyle, value: paragraphStyle, range: .init(location: 0, length: accumulator.length))

  return .init(attributedString: accumulator)
}
