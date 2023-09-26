// SPDX-License-Identifier: MIT

import IdentifiedCollections
import Library
import Neovim
import SwiftUI

class CmdlinesWindowController: NSWindowController, NSWindowDelegate {
  private let store: Store
  private let parentWindow: NSWindow
  private let viewController: CmdlinesViewController
  private var task: Task<Void, Never>?

  init(store: Store, parentWindow: NSWindow) {
    self.store = store
    self.parentWindow = parentWindow

    viewController = CmdlinesViewController(store: store)

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

        if stateUpdates.isCmdlinesUpdated || stateUpdates.isAppearanceUpdated || stateUpdates.isFontUpdated {
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
    guard let window else {
      return
    }

    viewController.reloadData()

    if store.cmdlines.filter(\.isVisible).isEmpty {
      parentWindow.removeChildWindow(window)
      window.setIsVisible(false)

    } else {
      parentWindow.addChildWindow(window, ordered: .above)
    }
  }

  func windowDidResize(_: Notification) {
    window!.setFrameOrigin(
      .init(
        x: parentWindow.frame.origin.x + (parentWindow.frame.width / 2) - (window!.frame.width / 2),
        y: parentWindow.frame.origin.y + (parentWindow.frame.height / 1.5) - (window!.frame.height / 2)
      )
    )
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

private final class CmdlinesViewController: NSViewController {
  func reloadData() {
    let containerSize = CGSize(width: 490, height: Double.greatestFiniteMagnitude)

    let attributedString = makeAttributedString()

    let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
    let size = CTFramesetterSuggestFrameSizeWithConstraints(
      framesetter,
      .init(location: 0, length: attributedString.length),
      nil,
      containerSize,
      nil
    )

    contentView.setFrameSize(size)
    preferredContentSize = .init(width: 500, height: min(size.height + 10, 240))

    let ctFrame = CTFramesetterCreateFrame(
      framesetter,
      .init(location: 0, length: attributedString.length),
      .init(rect: .init(origin: .zero, size: .init(width: ceil(size.width), height: ceil(size.height))), transform: nil),
      nil
    )

    contentView.ctFrame = ctFrame
    contentView.needsDisplay = true
  }

  private let store: Store
  private let scrollView = NSScrollView()
  private let contentView = CmdlinesContentView()

  init(store: Store) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    scrollView.automaticallyAdjustsContentInsets = false
    scrollView.contentInsets = .init(top: 5, left: 5, bottom: 5, right: 5)
    scrollView.documentView = contentView

    view = scrollView
  }

  private func makeAttributedString() -> NSAttributedString {
    let accumulator = NSMutableAttributedString()

    let sortedCmdlines = store.cmdlines.filter(\.isVisible).sorted(by: { $0.level < $1.level })
    for (cmdlineIndex, cmdline) in sortedCmdlines.enumerated() {
      let firstCharacter = NSAttributedString(string: cmdline.firstCharacter, attributes: [
        .font: store.font.nsFont(),
        .foregroundColor: store.appearance.defaultForegroundColor.appKit.withAlphaComponent(0.5),
      ])

      if !cmdline.blockLines.isEmpty {
        for blockLine in cmdline.blockLines {
          let lineAccumulator = firstCharacter.mutableCopy() as! NSMutableAttributedString

          for contentPart in blockLine {
            lineAccumulator.append(
              .init(
                string: contentPart.text,
                attributes: .init([
                  .font: store.font.nsFont(),
                  .foregroundColor: store.appearance.foregroundColor(for: contentPart.highlightID).appKit,
                ])
              )
            )
          }

          accumulator.append(lineAccumulator)
          accumulator.append(.init(string: "\n"))
        }
      }

      let attributedString = NSMutableAttributedString()
      attributedString.append(
        .init(
          string: "".padding(toLength: cmdline.indent, withPad: " ", startingAt: 0),
          attributes: [.font: store.font.nsFont()]
        )
      )
      for contentPart in cmdline.contentParts {
        attributedString.append(
          .init(string: contentPart.text, attributes: [
            .font: store.font.nsFont(),
            .foregroundColor: store.appearance.foregroundColor(for: contentPart.highlightID).appKit,
          ])
        )
      }

      if !cmdline.specialCharacter.isEmpty {
        let attributes: [NSAttributedString.Key: Any] = [
          .font: store.font.nsFont(),
          .foregroundColor: store.appearance.defaultSpecialColor.appKit,
        ]

        if cmdline.shiftAfterSpecialCharacter {
          attributedString.insert(
            .init(
              string: cmdline.specialCharacter,
              attributes: attributes
            ),
            at: cmdline.cursorPosition
          )

        } else {
          let range = NSRange(
            location: cmdline.cursorPosition,
            length: cmdline.specialCharacter.count
          )
          attributedString.replaceCharacters(
            in: range,
            with: cmdline.specialCharacter
          )
          attributedString.addAttributes(attributes, range: range)
        }

      } else if cmdline.cursorPosition > 0 {
        if cmdline.cursorPosition == attributedString.length {
          attributedString.append(.init(string: " "))
        }

        attributedString.addAttributes(
          [
            .foregroundColor: store.appearance.defaultBackgroundColor.appKit,
            .backgroundColor: store.appearance.defaultForegroundColor.appKit,
          ],
          range: .init(location: cmdline.cursorPosition, length: 1)
        )
      }

      accumulator.append(firstCharacter)
      accumulator.append(attributedString)

      if cmdlineIndex < store.cmdlines.count - 1 {
        accumulator.append(.init(string: "\n"))
      }
    }

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineBreakMode = .byCharWrapping
    paragraphStyle.allowsDefaultTighteningForTruncation = false
    accumulator.addAttribute(
      .paragraphStyle,
      value: paragraphStyle,
      range: .init(location: 0, length: accumulator.length)
    )

    return .init(attributedString: accumulator)
  }
}

private final class CmdlinesContentView: NSView {
  var ctFrame: CTFrame?

  override func draw(_ dirtyRect: NSRect) {
    guard let ctFrame else {
      return
    }

    let graphicsContext = NSGraphicsContext.current!
    let cgContext = graphicsContext.cgContext

    cgContext.saveGState()

    dirtyRect.clip()

    CTFrameDraw(ctFrame, cgContext)

    cgContext.restoreGState()

    graphicsContext.flushGraphics()
  }
}
