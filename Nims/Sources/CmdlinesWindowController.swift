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

struct CmdlinesView: View {
  var cmdlines: IdentifiedArrayOf<Cmdline>
  var font: NimsFont
  var appearance: Appearance

  var body: some View {
    ForEach(cmdlines, id: \.level) { cmdline in
      VStack(alignment: .leading, spacing: 4) {
        if !cmdline.prompt.isEmpty {
          let attributedString = AttributedString(
            cmdline.prompt,
            attributes: .init([
              .font: font.nsFont(isItalic: true),
              .foregroundColor: appearance.defaultForegroundColor.appKit
                .withAlphaComponent(0.6),
            ])
          )
          Text(attributedString)
        }

        HStack(alignment: .firstTextBaseline, spacing: 10) {
          if !cmdline.firstCharacter.isEmpty {
            let attributedString = AttributedString(
              cmdline.firstCharacter,
              attributes: .init([
                .font: font.nsFont(isBold: true),
                .foregroundColor: appearance.defaultForegroundColor.appKit,
              ])
            )
            Text(attributedString)
              .frame(width: 20, height: 20)
              .background(
                appearance.defaultForegroundColor.swiftUI
                  .opacity(0.2)
              )
          }

          ZStack(alignment: .leading) {
            let attributedString = makeContentAttributedString(cmdline: cmdline)
            Text(attributedString)

            let isCursorAtEnd = cmdline.cursorPosition == attributedString.characters.count
            let isBlockCursorShape = isCursorAtEnd || !cmdline.specialCharacter.isEmpty

            let integerFrame = IntegerRectangle(
              origin: .init(column: cmdline.cursorPosition, row: 0),
              size: .init(columnsCount: 1, rowsCount: 1)
            )
            let frame = integerFrame * font.cellSize

            Rectangle()
              .fill(appearance.defaultForegroundColor.swiftUI)
              .frame(width: isBlockCursorShape ? frame.width : frame.width * 0.25, height: frame.height)
              .offset(x: frame.minX, y: frame.minY)

            if !cmdline.specialCharacter.isEmpty {
              let attributedString = AttributedString(
                cmdline.specialCharacter,
                attributes: .init([
                  .font: font.nsFont(),
                  .foregroundColor: appearance.defaultForegroundColor.appKit,
                ])
              )
              Text(attributedString)
                .offset(x: frame.minX, y: frame.minY)
            }
          }

          Spacer()
        }
      }
      .padding(.init(top: 10, leading: 16, bottom: 10, trailing: 16))
      .frame(minWidth: 640)
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
    }
  }

  @MainActor
  private func makeContentAttributedString(cmdline: Cmdline) -> AttributedString {
    var accumulator = AttributedString()

    if !cmdline.blockLines.isEmpty {
      for blockLine in cmdline.blockLines {
        var lineAccumulator = AttributedString()

        for contentPart in blockLine {
          let attributedString = AttributedString(
            contentPart.text,
            attributes: .init([
              .font: font.nsFont(),
              .foregroundColor: appearance.foregroundColor(for: contentPart.highlightID).swiftUI,
              .backgroundColor: appearance.backgroundColor(for: contentPart.highlightID).swiftUI,
            ])
          )
          lineAccumulator.append(attributedString)
        }

        accumulator.append(lineAccumulator)
        accumulator.append(AttributedString("\n"))
      }
    }

    var attributedString = cmdline.contentParts
      .map { contentPart -> AttributedString in
        AttributedString(
          contentPart.text,
          attributes: .init([
            .font: font.nsFont(),
            .foregroundColor: appearance.foregroundColor(for: contentPart.highlightID).swiftUI,
            .backgroundColor: appearance.backgroundColor(for: contentPart.highlightID).swiftUI,
          ])
        )
      }
      .reduce(AttributedString()) { result, next in
        var copy = result
        copy.append(next)
        return copy
      }

    if !cmdline.specialCharacter.isEmpty, cmdline.shiftAfterSpecialCharacter {
      let insertPosition = attributedString.index(
        attributedString.startIndex,
        offsetByCharacters: cmdline.cursorPosition
      )

      attributedString.insert(
        AttributedString(
          "".padding(toLength: cmdline.specialCharacter.count, withPad: " ", startingAt: 0),
          attributes: .init([
            .font: font,
            .foregroundColor: appearance.defaultSpecialColor,
          ])
        ),
        at: insertPosition
      )
    }

    accumulator.append(attributedString)

    return accumulator
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
      .init(rect: .init(origin: .zero, size: size), transform: nil),
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

      let attributedString = firstCharacter.mutableCopy() as! NSMutableAttributedString
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

      if !cmdline.specialCharacter.isEmpty, cmdline.shiftAfterSpecialCharacter {
        attributedString.insert(
          .init(
            string: "".padding(toLength: cmdline.specialCharacter.count, withPad: " ", startingAt: 0),
            attributes: [.font: store.font.nsFont(), .foregroundColor: store.appearance.defaultSpecialColor.appKit]
          ),
          at: cmdline.cursorPosition + 1
        )
      }

      accumulator.append(attributedString)

      if cmdlineIndex < store.cmdlines.count - 1 {
        accumulator.append(.init(string: "\n"))
      }
    }

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
