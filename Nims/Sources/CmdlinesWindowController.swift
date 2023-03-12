// SPDX-License-Identifier: MIT

import IdentifiedCollections
import Library
import Neovim
import SwiftUI

class CmdlinesWindowController: NSWindowController {
  private let store: Store
  private let viewController: NSHostingController<CmdlinesView>
  private var task: Task<Void, Never>?

  init(store: Store) {
    self.store = store

    viewController = NSHostingController<CmdlinesView>(
      rootView: .init(cmdlines: store.cmdlines, font: store.state.font, appearance: store.appearance)
    )
    viewController.sizingOptions = .preferredContentSize

    let window = NSWindow(contentViewController: viewController)
    window.styleMask = [.borderless]
    window.isMovableByWindowBackground = false
    window.isOpaque = false
    window.backgroundColor = .clear
    window.level = .floating

    super.init(window: window)

    window.delegate = self

    task = Task {
      for await stateUpdates in store.stateUpdatesStream() {
        guard !Task.isCancelled else {
          return
        }

        if stateUpdates.isCmdlinesUpdated || stateUpdates.isAppearanceUpdated || stateUpdates.isFontUpdated {
          viewController.rootView = .init(
            cmdlines: store.cmdlines,
            font: store.state.font,
            appearance: store.appearance
          )
        }

        if stateUpdates.isCmdlinesUpdated {
          self.window!.setIsVisible(!store.cmdlines.isEmpty)

          if !store.cmdlines.isEmpty {
            self.window!.orderFront(nil)
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
}

extension CmdlinesWindowController: NSWindowDelegate {
  func windowDidResize(_: Notification) {
    guard let window, let screen = window.screen else {
      return
    }

    window.setFrameOrigin(
      .init(
        x: (screen.frame.width - window.frame.width) / 2,
        y: (screen.frame.height - window.frame.height) / 1.5
      )
    )
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
      .frame(idealWidth: 640)
      .background {
        let rectangle = Rectangle()

        rectangle
          .fill(
            appearance.defaultBackgroundColor.swiftUI.opacity(0.9)
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
