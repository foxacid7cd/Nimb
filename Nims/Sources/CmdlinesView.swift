// SPDX-License-Identifier: MIT

import ComposableArchitecture
import Foundation
import IdentifiedCollections
import Library
import Neovim
import SwiftUI

@MainActor
struct CmdlinesView: View {
  init(store: StoreOf<RunningInstanceReducer>) {
    self.store = store
  }

  private var store: StoreOf<RunningInstanceReducer>

  public var body: some View {
    WithViewStore(
      store,
      observe: { $0 },
      removeDuplicates: { $0.cmdlinesUpdateFlag == $1.cmdlinesUpdateFlag }
    ) { viewStore in
      let state = viewStore.state

      VStack(alignment: .center, spacing: 0) {
        Spacer()
          .frame(height: 88)

        ForEach(state.cmdlines.values) { cmdline in
          CmdlineView(cmdline: cmdline)
        }

        Spacer()
      }
      .background {
        Rectangle()
          .fill(.black.opacity(0.75))
      }
    }
  }
}

@MainActor
struct CmdlineView: View {
  init(cmdline: Cmdline) {
    self.cmdline = cmdline
  }

  private var cmdline: Cmdline

  @Environment(\.nimsFont)
  private var font: NimsFont

  @Environment(\.appearance)
  private var appearance: Appearance

  public var body: some View {
    HStack {
      Spacer()

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
            let attributedString = makeContentAttributedString(font: font.nsFont())
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
                  .font: font,
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
      .frame(maxWidth: 860, minHeight: 44)
      .background(appearance.defaultBackgroundColor.swiftUI)

      Spacer()
    }
  }

  private func makeContentAttributedString(font: NSFont) -> AttributedString {
    var accumulator = AttributedString()

    if !cmdline.blockLines.isEmpty {
      for blockLine in cmdline.blockLines {
        var lineAccumulator = AttributedString()

        for contentPart in blockLine {
          let attributedString = AttributedString(
            contentPart.text,
            attributes: .init([
              .font: font,
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
            .font: font,
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
          attributes: .init([.font: font])
        ),
        at: insertPosition
      )
    }

    accumulator.append(attributedString)

    return accumulator
  }
}
