// SPDX-License-Identifier: MIT

import AppKit
import Combine
import ComposableArchitecture
import CustomDump
import Library
import Neovim
import SwiftUI

final class AppDelegate: NSObject {
  private var cancellables = Set<AnyCancellable>()

  @MainActor
  func bind(font: NimsFont, store: StoreOf<RunningInstanceReducer>) {
    cancellables.forEach { $0.cancel() }
    cancellables.removeAll(keepingCapacity: true)

    bindMsgShowsWindow(font: font, store: store)
    bindCmdlinesWindow(font: font, store: store)
  }

  @MainActor
  private func bindMsgShowsWindow(font: NimsFont, store: StoreOf<RunningInstanceReducer>) {
    let state = ViewStore(
      store,
      observe: { $0 },
      removeDuplicates: { lhs, rhs in
        guard
          lhs.msgShowsUpdateFlag == rhs.msgShowsUpdateFlag,
          lhs.appearanceUpdateFlag == rhs.appearanceUpdateFlag
        else {
          return false
        }

        return true
      }
    )

    let viewController = NSHostingController<MsgShowsView>(
      rootView: .init(font: font, state: state)
    )
    viewController.sizingOptions = .preferredContentSize

    let window = Window(contentViewController: viewController)
    window.styleMask = [.borderless]
    window.isMovableByWindowBackground = true
    window.isOpaque = false
    window.backgroundColor = .clear
    window.setFrameOrigin(.init(x: 1200, y: 200))

    state.publisher
      .sink { state in
        if !state.msgShows.isEmpty {
          window.setIsVisible(true)
        } else {
          window.setIsVisible(false)
        }
      }
      .store(in: &cancellables)
  }

  @MainActor
  private func bindCmdlinesWindow(font: NimsFont, store: StoreOf<RunningInstanceReducer>) {
    let state = ViewStore(
      store,
      observe: { $0 },
      removeDuplicates: { lhs, rhs in
        guard
          lhs.cmdlinesUpdateFlag == rhs.cmdlinesUpdateFlag,
          lhs.appearanceUpdateFlag == rhs.appearanceUpdateFlag
        else {
          return false
        }

        return true
      }
    )

    let viewController = NSHostingController<CmdlinesView>(
      rootView: .init(font: font, state: state)
    )
    viewController.sizingOptions = .preferredContentSize

    let window = Window(contentViewController: viewController)
    window.styleMask = [.borderless]
    window.isMovableByWindowBackground = true
    window.isOpaque = false
    window.backgroundColor = .clear
    window.level = .floating
    window.setFrameOrigin(.init(x: 200, y: 200))

    state.publisher
      .sink { state in
        if !state.cmdlines.isEmpty {
          window.setIsVisible(true)
        } else {
          window.setIsVisible(false)
        }
      }
      .store(in: &cancellables)
  }
}

extension AppDelegate: NSApplicationDelegate {
  func applicationDidFinishLaunching(_: Notification) {}
}

private final class Window: NSWindow {
  override var canBecomeKey: Bool {
    false
  }
}

struct MsgShowsView: View {
  var font: NimsFont

  @ObservedObject
  var state: ViewStoreOf<RunningInstanceReducer>

  var body: some View {
    Text(makeContentAttributedString())
      .lineLimit(nil)
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
            state.appearance.defaultBackgroundColor.swiftUI.opacity(0.9)
          )

        rectangle
          .stroke(
            state.appearance.defaultForegroundColor.swiftUI.opacity(0.1),
            lineWidth: 1
          )
      }
  }

  private func makeContentAttributedString() -> AttributedString {
    var accumulator = AttributedString()

    for (index, msgShow) in state.msgShows.values.enumerated() {
      msgShow.contentParts
        .map { contentPart -> AttributedString in
          AttributedString(
            contentPart.text,
            attributes: .init([
              .font: font.nsFont(),
              .foregroundColor: state.appearance.foregroundColor(for: contentPart.highlightID).swiftUI,
              .backgroundColor: contentPart.highlightID.isDefault ? SwiftUI.Color.clear : state.appearance.backgroundColor(for: contentPart.highlightID).swiftUI,
            ])
          )
        }
        .forEach { accumulator.append($0) }

      if index < state.msgShows.count - 1 {
        accumulator.append("\n" as AttributedString)
      }
    }

    return accumulator
  }
}

struct CmdlinesView: View {
  var font: NimsFont

  @ObservedObject
  var state: ViewStoreOf<RunningInstanceReducer>

  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      ForEach(state.cmdlines.values, id: \.id) { cmdline in
        HStack {
          Spacer()

          VStack(alignment: .leading, spacing: 4) {
            if !cmdline.prompt.isEmpty {
              let attributedString = AttributedString(
                cmdline.prompt,
                attributes: .init([
                  .font: font.nsFont(isItalic: true),
                  .foregroundColor: state.appearance.defaultForegroundColor.appKit
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
                    .foregroundColor: state.appearance.defaultForegroundColor.appKit,
                  ])
                )
                Text(attributedString)
                  .frame(width: 20, height: 20)
                  .background(
                    state.appearance.defaultForegroundColor.swiftUI
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
                  .fill(state.appearance.defaultForegroundColor.swiftUI)
                  .frame(width: isBlockCursorShape ? frame.width : frame.width * 0.25, height: frame.height)
                  .offset(x: frame.minX, y: frame.minY)

                if !cmdline.specialCharacter.isEmpty {
                  let attributedString = AttributedString(
                    cmdline.specialCharacter,
                    attributes: .init([
                      .font: font.nsFont(),
                      .foregroundColor: state.appearance.defaultForegroundColor.appKit,
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
          .frame(idealWidth: 640, minHeight: 44)
          .background {
            let rectangle = Rectangle()

            rectangle
              .fill(
                state.appearance.defaultBackgroundColor.swiftUI.opacity(0.9)
              )

            rectangle
              .stroke(
                state.appearance.defaultForegroundColor.swiftUI.opacity(0.1),
                lineWidth: 1
              )
          }

          Spacer()
        }
      }
    }
  }

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
              .foregroundColor: state.appearance.foregroundColor(for: contentPart.highlightID).swiftUI,
              .backgroundColor: state.appearance.backgroundColor(for: contentPart.highlightID).swiftUI,
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
            .foregroundColor: state.appearance.foregroundColor(for: contentPart.highlightID).swiftUI,
            .backgroundColor: state.appearance.backgroundColor(for: contentPart.highlightID).swiftUI,
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
          attributes: .init([.font: font])
        ),
        at: insertPosition
      )
    }

    accumulator.append(attributedString)

    return accumulator
  }
}
