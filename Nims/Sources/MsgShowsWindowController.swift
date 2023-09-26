// SPDX-License-Identifier: MIT

import AppKit
import Library
import Neovim
import SwiftUI

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
    window.alphaValue = 0.95
    window.backgroundColor = .underPageBackgroundColor

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
    let maxSize = CGSize(width: 1024, height: 768)

    let attributedString = makeContentAttributedString(
      msgShows: store.msgShows,
      font: store.font,
      appearance: store.appearance
    )
    let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
    let size = CTFramesetterSuggestFrameSizeWithConstraints(
      framesetter,
      .init(location: 0, length: attributedString.length),
      nil,
      .init(width: maxSize.width, height: .greatestFiniteMagnitude),
      nil
    )

    viewController.preferredContentSize = .init(
      width: min(maxSize.width, size.width) + 10,
      height: min(maxSize.height, size.height) + 10
    )

    let ctFrame = CTFramesetterCreateFrame(
      framesetter,
      .init(location: 0, length: attributedString.length),
      CGPath(
        rect: .init(
          origin: .zero,
          size: .init(width: ceil(size.width), height: ceil(size.height))
        ),
        transform: nil
      ),
      nil
    )
    viewController.update(contentSize: size, ctFrame: ctFrame)

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
  private var maxSize = CGSize(width: 0, height: 0)

  init(store: Store) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    scrollView.scrollsDynamically = false
    scrollView.horizontalScrollElasticity = .none
    scrollView.automaticallyAdjustsContentInsets = false
    scrollView.contentInsets = .init(top: 5, left: 5, bottom: 5, right: 5)
    scrollView.documentView = documentView

    view = scrollView
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
        string: contentPart.text,
        attributes: [
          .font: font.nsFont(),
          .foregroundColor: appearance.foregroundColor(for: contentPart.highlightID).appKit,
          .backgroundColor: contentPart.highlightID.isDefault ? NSColor.clear : appearance.backgroundColor(for: contentPart.highlightID).appKit,
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
  accumulator.addAttributes([.paragraphStyle: paragraphStyle], range: .init(location: 0, length: accumulator.length))
  return .init(attributedString: accumulator)
}
