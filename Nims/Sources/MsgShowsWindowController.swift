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

    viewController = MsgShowsViewController()

    let window = Window(contentViewController: viewController)
    window.styleMask = [.borderless]
    window.isMovableByWindowBackground = true
    window.isOpaque = false
    window.backgroundColor = .clear
    window.setIsVisible(false)

    super.init(window: window)

    window.delegate = self

    task = Task { [weak self] in
      for await stateUpdates in store.stateUpdatesStream() {
        guard let self, !Task.isCancelled else {
          break
        }

        if stateUpdates.isMsgShowsUpdated || stateUpdates.isAppearanceUpdated || stateUpdates.isFontUpdated {
          viewController.update(
            msgShows: store.msgShows,
            font: store.font,
            appearance: store.appearance,
            maxSize: parentWindow.frame.size
          )
        }

        if stateUpdates.isMsgShowsUpdated {
          updateWindowOrigin()

          if store.msgShows.isEmpty {
            parentWindow.removeChildWindow(self.window!)
            self.window?.setIsVisible(false)
          } else {
            parentWindow.addChildWindow(self.window!, ordered: .above)
          }
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

  private func updateWindowOrigin() {
    guard let window else {
      return
    }

    window.setFrameOrigin(
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

struct MsgShowsView: View {
  var msgShows: [MsgShow]
  var font: NimsFont
  var appearance: Appearance
  var maxWidth: Double

  var body: some View {
    Text(makeContentAttributedString())
      .lineLimit(3)
      .padding(
        .init(
          top: font.cellHeight,
          leading: font.cellWidth * 2.5,
          bottom: font.cellHeight,
          trailing: font.cellWidth * 2.5
        )
      )
      .background {
        let rectangle = Rectangle()

        rectangle
          .fill(
            appearance.defaultBackgroundColor.swiftUI.opacity(0.95)
          )

        rectangle
          .stroke(
            appearance.defaultForegroundColor.swiftUI.opacity(0.1),
            lineWidth: 1
          )
      }
      .frame(maxWidth: maxWidth)
  }

  @MainActor
  private func makeContentAttributedString() -> AttributedString {
    var accumulator = AttributedString()

    for (index, msgShow) in msgShows.enumerated() {
      msgShow.contentParts
        .map { contentPart -> AttributedString in
          AttributedString(
            contentPart.text,
            attributes: .init([
              .font: font.nsFont(),
              .foregroundColor: appearance.foregroundColor(for: contentPart.highlightID).swiftUI,
              .backgroundColor: contentPart.highlightID.isDefault ? SwiftUI.Color.clear : appearance.backgroundColor(for: contentPart.highlightID).swiftUI,
            ])
          )
        }
        .forEach { accumulator.append($0) }

      if index < msgShows.count - 1 {
        accumulator.append("\n" as AttributedString)
      }
    }

    return accumulator
  }
}

final class MsgShowsViewController: NSViewController {
  private let scrollView = NSScrollView()
  private let documentView = DocumentView()
  private var maxSize = CGSize(width: 0, height: 0)

  init() {
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    let view = NSView()

    scrollView.allowsMagnification = false
    scrollView.scrollsDynamically = false
    scrollView.horizontalScrollElasticity = .none
    scrollView.documentView = documentView
    view.addSubview(scrollView)

    self.view = view
  }

  func update(msgShows: [MsgShow], font: NimsFont, appearance: Appearance, maxSize: CGSize) {
    self.maxSize = maxSize

    scrollView.backgroundColor = appearance.defaultBackgroundColor.appKit

    let horizontalInset: CGFloat = 8
    let verticalInset: CGFloat = 8
    scrollView.contentInsets = .init(
      top: verticalInset,
      left: horizontalInset,
      bottom: verticalInset,
      right: horizontalInset
    )

    let containerSize = NSSize(
      width: maxSize.width - horizontalInset * 2,
      height: CGFloat.greatestFiniteMagnitude
    )
    documentView.containerSize = containerSize

    let attributedString = makeContentAttributedString(msgShows: msgShows, font: font, appearance: appearance)
    let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
    let boundingSize = CTFramesetterSuggestFrameSizeWithConstraints(
      framesetter,
      .init(location: 0, length: attributedString.length),
      nil,
      containerSize,
      nil
    )
    documentView.setFrameSize(boundingSize)

    let frame = CTFramesetterCreateFrame(
      framesetter,
      .init(location: 0, length: attributedString.length),
      CGPath(
        rect: .init(
          origin: .init(x: horizontalInset, y: verticalInset),
          size: boundingSize
        ),
        transform: nil
      ),
      nil
    )
    documentView.ctFrame = frame
    documentView.needsDisplay = true

    let size = CGSize(
      width: min(maxSize.width, boundingSize.width + horizontalInset * 2),
      height: min(maxSize.height, boundingSize.height + verticalInset * 2)
    )
    preferredContentSize = size
    scrollView.frame.size = size
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
  var containerSize = CGSize()

  override func draw(_ dirtyRect: NSRect) {
    guard let ctFrame else {
      return
    }

    let graphicsContext = NSGraphicsContext.current!
    graphicsContext.cgContext.clip(to: [dirtyRect])

    NSColor.clear.setFill()
    dirtyRect.fill()

    CTFrameDraw(ctFrame, graphicsContext.cgContext)

    graphicsContext.flushGraphics()
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
