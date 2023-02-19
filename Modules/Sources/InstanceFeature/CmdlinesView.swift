// SPDX-License-Identifier: MIT

import ComposableArchitecture
import IdentifiedCollections
import Library
import SwiftUI

@MainActor
public struct CmdlinesView: View {
  public var instanceViewModel: InstanceViewModel
  public var store: StoreOf<Instance>

  public var body: some View {
    WithViewStore(
      store,
      observe: { $0 },
      removeDuplicates: { $0.cmdlineUpdateFlag == $1.cmdlineUpdateFlag }
    ) { viewStore in
      let state = viewStore.state

      let horizontalPadding = instanceViewModel.font.cellWidth * 4
      let verticalPadding = instanceViewModel.font.cellHeight * 2

      VStack(alignment: .center, spacing: 0) {
        ForEach(state.cmdlines) { cmdline in
          CmdlineView(cmdline: cmdline, instanceViewModel: instanceViewModel)
        }
        Spacer()
      }
      .padding(EdgeInsets(
        top: verticalPadding + 32,
        leading: horizontalPadding,
        bottom: verticalPadding,
        trailing: horizontalPadding
      ))
      .background {
        Rectangle()
          .fill(.black.opacity(0.5))
      }
    }
  }
}

@MainActor
public struct CmdlineView: View {
  public var cmdline: Cmdline
  public var instanceViewModel: InstanceViewModel

  public var body: some View {
    let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    let cellSize = CGSize(width: font.makeCellWidth(), height: font.makeCellHeight())

    HStack {
      VStack(alignment: .leading, spacing: 0) {
        if !cmdline.prompt.isEmpty {
          let attributedString = AttributedString(
            cmdline.prompt + "\n",
            attributes: .init([
              .font: font,
              .foregroundColor: instanceViewModel.defaultForegroundColor.appKit
                .withAlphaComponent(0.6),
              .backgroundColor: instanceViewModel.defaultBackgroundColor.appKit,
            ])
          )
          Text(attributedString)
        }

        HStack(alignment: .firstTextBaseline, spacing: 2) {
          if !cmdline.firstCharacter.isEmpty {
            let attributedString = AttributedString(
              cmdline.firstCharacter,
              attributes: .init([
                .font: NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask),
                .foregroundColor: instanceViewModel.defaultForegroundColor.appKit,
                .backgroundColor: instanceViewModel.defaultBackgroundColor.appKit,
              ])
            )
            Text(attributedString)
          }

          ZStack(alignment: .topLeading) {
            let attributedString = makeContentAttributedString(font: font)
            Text(attributedString)

            let isCursorAtEnd = cmdline.cursorPosition == attributedString.characters.count
            let isBlockCursorShape = isCursorAtEnd || !cmdline.specialCharacter.isEmpty

            let integerFrame = IntegerRectangle(
              origin: .init(column: cmdline.cursorPosition, row: 0),
              size: .init(columnsCount: 1, rowsCount: 1)
            )
            let frame = integerFrame * cellSize

            Rectangle()
              .fill(instanceViewModel.defaultForegroundColor.swiftUI)
              .frame(width: isBlockCursorShape ? frame.width : frame.width * 0.25, height: frame.height)
              .offset(x: frame.minX, y: frame.minY)

            if !cmdline.specialCharacter.isEmpty {
              let attributedString = AttributedString(
                cmdline.specialCharacter,
                attributes: .init([
                  .font: font,
                  .foregroundColor: instanceViewModel.defaultBackgroundColor.appKit,
                ])
              )
              Text(attributedString)
                .offset(x: frame.minX, y: frame.minY)
            }
          }
        }
      }

      Spacer()
    }
    .padding(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20))
    .background(instanceViewModel.defaultBackgroundColor.swiftUI)
  }

  private func makeContentAttributedString(font: NSFont) -> AttributedString {
    var attributedString = cmdline.contentParts
      .map { contentPart -> AttributedString in
        let highlight = instanceViewModel.highlights[id: contentPart.highlightID]

        return AttributedString(
          contentPart.text,
          attributes: .init([
            .font: font,
            .foregroundColor: highlight?.foregroundColor?.appKit ?? instanceViewModel.defaultForegroundColor.appKit,
            .backgroundColor: highlight?.backgroundColor?.appKit ?? instanceViewModel.defaultBackgroundColor.appKit,
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

    return attributedString
  }
}
