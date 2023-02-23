// SPDX-License-Identifier: MIT

import ComposableArchitecture
import Foundation
import IdentifiedCollections
import Library
import SwiftUI

@MainActor
public struct CmdlinesView: View {
  public var store: Store<Model, Action>

  public struct Model: Sendable {
    public init(cmdlines: IdentifiedArrayOf<Cmdline>, cmdlineUpdateFlag: Bool) {
      self.cmdlines = cmdlines
      self.cmdlineUpdateFlag = cmdlineUpdateFlag
    }

    public var cmdlines: IdentifiedArrayOf<Cmdline>
    public var cmdlineUpdateFlag: Bool
  }

  public enum Action: Sendable {}

  @Environment(\.nimsAppearance)
  private var nimsAppearance: NimsAppearance

  public var body: some View {
    WithViewStore(
      store,
      observe: { $0 },
      removeDuplicates: { $0.cmdlineUpdateFlag == $1.cmdlineUpdateFlag }
    ) { viewStore in
      let state = viewStore.state

      let horizontalPadding = nimsAppearance.cellWidth * 4
      let verticalPadding = nimsAppearance.cellHeight * 2

      VStack(alignment: .center, spacing: 0) {
        ForEach(state.cmdlines) { cmdline in
          CmdlineView(cmdline: cmdline)
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

  @Environment(\.nimsAppearance)
  private var nimsAppearance: NimsAppearance

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
              .foregroundColor: nimsAppearance.defaultForegroundColor.appKit
                .withAlphaComponent(0.6),
              .backgroundColor: nimsAppearance.defaultBackgroundColor.appKit,
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
                .foregroundColor: nimsAppearance.defaultForegroundColor.appKit,
                .backgroundColor: nimsAppearance.defaultBackgroundColor.appKit,
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
              .fill(nimsAppearance.defaultForegroundColor.swiftUI)
              .frame(width: isBlockCursorShape ? frame.width : frame.width * 0.25, height: frame.height)
              .offset(x: frame.minX, y: frame.minY)

            if !cmdline.specialCharacter.isEmpty {
              let attributedString = AttributedString(
                cmdline.specialCharacter,
                attributes: .init([
                  .font: font,
                  .foregroundColor: nimsAppearance.defaultBackgroundColor.appKit,
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
    .background(nimsAppearance.defaultBackgroundColor.swiftUI)
  }

  private func makeContentAttributedString(font: NSFont) -> AttributedString {
    var accumulator = AttributedString()

    if !cmdline.blockLines.isEmpty {
      for blockLine in cmdline.blockLines {
        var lineAccumulator = AttributedString()

        for contentPart in blockLine {
          let highlight = nimsAppearance.highlights[id: contentPart.highlightID]

          let attributedString = AttributedString(
            contentPart.text,
            attributes: .init([
              .font: font,
              .foregroundColor: highlight?.foregroundColor?.appKit ?? nimsAppearance.defaultForegroundColor.appKit,
              .backgroundColor: highlight?.backgroundColor?.appKit ?? nimsAppearance.defaultBackgroundColor.appKit,
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
        let highlight = nimsAppearance.highlights[id: contentPart.highlightID]

        return AttributedString(
          contentPart.text,
          attributes: .init([
            .font: font,
            .foregroundColor: highlight?.foregroundColor?.appKit ?? nimsAppearance.defaultForegroundColor.appKit,
            .backgroundColor: highlight?.backgroundColor?.appKit ?? nimsAppearance.defaultBackgroundColor.appKit,
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
