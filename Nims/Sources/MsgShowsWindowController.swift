// SPDX-License-Identifier: MIT

import AppKit
import Library
import Neovim
import SwiftUI

class MsgShowsWindowController: NSWindowController {
  private let store: Store
  private let viewController: NSHostingController<MsgShowsView>
  private var task: Task<Void, Never>?

  init(store: Store) {
    self.store = store

    viewController = NSHostingController<MsgShowsView>(
      rootView: .init(msgShows: store.state.msgShows, font: store.state.font, appearance: store.state.appearance)
    )
    viewController.sizingOptions = .preferredContentSize

    let window = NSPanel(contentViewController: viewController)
    window.styleMask = [.borderless, .utilityWindow]
    window.isMovableByWindowBackground = true
    window.isOpaque = false
    window.backgroundColor = .clear
    window.setFrameOrigin(.init(x: 1200, y: 200))

    super.init(window: window)

    task = Task {
      for await stateUpdates in store.stateUpdatesStream() {
        guard !Task.isCancelled else {
          return
        }

        if stateUpdates.isMsgShowsUpdated || stateUpdates.isAppearanceUpdated || stateUpdates.isFontUpdated {
          viewController.rootView = .init(
            msgShows: store.state.msgShows,
            font: store.state.font,
            appearance: store.state.appearance
          )
        }

        if stateUpdates.isMsgShowsUpdated {
          if store.state.msgShows.isEmpty {
            self.close()

          } else {
            self.showWindow(nil)
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

struct MsgShowsView: View {
  var msgShows: [MsgShow]
  var font: NimsFont
  var appearance: Appearance

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
            appearance.defaultBackgroundColor.swiftUI.opacity(0.9)
          )

        rectangle
          .stroke(
            appearance.defaultForegroundColor.swiftUI.opacity(0.1),
            lineWidth: 1
          )
      }
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
