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
    public init(cmdlines: IntKeyedDictionary<Cmdline>, cmdlineUpdateFlag: Bool) {
      self.cmdlines = cmdlines
      self.cmdlineUpdateFlag = cmdlineUpdateFlag
    }

    public var cmdlines: IntKeyedDictionary<Cmdline>
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
public struct CmdlineView: View {
  public var cmdline: Cmdline

  @Environment(\.nimsAppearance)
  private var nimsAppearance: NimsAppearance

  public var body: some View {
    HStack {
      Spacer()

      VStack(alignment: .leading, spacing: 4) {
        if !cmdline.prompt.isEmpty {
          let attributedString = AttributedString(
            cmdline.prompt,
            attributes: .init([
              .font: nimsAppearance.font.nsFont(isItalic: true),
              .foregroundColor: nimsAppearance.defaultForegroundColor.appKit
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
                .font: nimsAppearance.font.nsFont(isBold: true),
                .foregroundColor: nimsAppearance.defaultForegroundColor.appKit,
              ])
            )
            Text(attributedString)
              .frame(width: 20, height: 20)
              .background(
                nimsAppearance.defaultForegroundColor.swiftUI
                  .opacity(0.2)
              )
          }

          ZStack(alignment: .leading) {
            let attributedString = makeContentAttributedString(font: nimsAppearance.font.nsFont())
            Text(attributedString)

            let isCursorAtEnd = cmdline.cursorPosition == attributedString.characters.count
            let isBlockCursorShape = isCursorAtEnd || !cmdline.specialCharacter.isEmpty

            let integerFrame = IntegerRectangle(
              origin: .init(column: cmdline.cursorPosition, row: 0),
              size: .init(columnsCount: 1, rowsCount: 1)
            )
            let frame = integerFrame * nimsAppearance.cellSize

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

          Spacer()
        }
      }
      .padding(.init(top: 10, leading: 16, bottom: 10, trailing: 16))
      .frame(maxWidth: 640, minHeight: 44)
      .background(nimsAppearance.defaultBackgroundColor.swiftUI)

      Spacer()
    }
  }

  private func makeContentAttributedString(font: NSFont) -> AttributedString {
    var accumulator = AttributedString()

    if !cmdline.blockLines.isEmpty {
      for blockLine in cmdline.blockLines {
        var lineAccumulator = AttributedString()

        for contentPart in blockLine {
          let highlight = nimsAppearance.highlights[contentPart.highlightID.rawValue]

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
        let highlight = nimsAppearance.highlights[contentPart.highlightID.rawValue]

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
