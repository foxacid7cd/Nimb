// SPDX-License-Identifier: MIT

import AppKit
import Library
import Neovim
import SwiftUI

class MsgShowsWindowController: NSWindowController {
  private let store: Store
  private let parentWindow: NSWindow
  private let viewController: NSHostingController<MsgShowsView>
  private var task: Task<Void, Never>?

  init(store: Store, parentWindow: NSWindow) {
    self.store = store
    self.parentWindow = parentWindow

    viewController = NSHostingController<MsgShowsView>(
      rootView: .init(msgShows: store.msgShows, font: store.font, appearance: store.appearance)
    )
    viewController.sizingOptions = .preferredContentSize

    let window = NSWindow(contentViewController: viewController)
    window.styleMask = [.borderless]
    window.isMovableByWindowBackground = true
    window.isOpaque = false
    window.backgroundColor = .clear

    super.init(window: window)

    window.delegate = self

    task = Task {
      for await stateUpdates in store.stateUpdatesStream() {
        guard !Task.isCancelled else {
          return
        }

        if stateUpdates.isMsgShowsUpdated || stateUpdates.isAppearanceUpdated || stateUpdates.isFontUpdated {
          viewController.rootView = .init(
            msgShows: store.msgShows,
            font: store.font,
            appearance: store.appearance
          )
        }

        if stateUpdates.isMsgShowsUpdated {
          updateWindowOrigin()

          self.window!.setIsVisible(!store.msgShows.isEmpty)

          if !store.msgShows.isEmpty {
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
            appearance.defaultBackgroundColor.swiftUI.opacity(0.95)
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
