// SPDX-License-Identifier: MIT

import AppKit
import Combine
import ComposableArchitecture
import CustomDump
import Library
import Neovim
import SwiftUI

final class AppDelegate: NSObject {
  private var viewStoreCancellable: AnyCancellable?

  @MainActor
  func bind(store: StoreOf<RunningInstanceReducer>) {
    viewStoreCancellable?.cancel()
    viewStoreCancellable = nil

    let viewStore = ViewStore(
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

    let viewController = ViewController(viewStore)

    let window = Window(contentViewController: viewController)
    window.styleMask = [.borderless]
    window.isMovableByWindowBackground = true
    window.isOpaque = false
    window.backgroundColor = .clear

    viewStoreCancellable = viewStore.publisher
      .sink { state in
        viewController.render()

        if !state.msgShows.isEmpty {
          window.setIsVisible(true)
        } else {
          window.setIsVisible(false)
        }
      }
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

private final class ViewController: NSHostingController<SwiftUIView> {
  private let viewStore: ViewStoreOf<RunningInstanceReducer>
  private var font = NimsFont(.monospacedSystemFont(ofSize: 12, weight: .regular))

  init(_ viewStore: ViewStoreOf<RunningInstanceReducer>) {
    self.viewStore = viewStore
    super.init(rootView: .init())

    sizingOptions = .preferredContentSize
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func render() {
    rootView.cellWidth = font.cellWidth
    rootView.cellHeight = font.cellHeight
    rootView.backgroundColor = viewStore.appearance.defaultBackgroundColor.swiftUI
    rootView.foregroundColor = viewStore.appearance.defaultForegroundColor.swiftUI
    rootView.attributedString = makeContentAttributedString(msgShows: viewStore.msgShows)
  }

  private func makeContentAttributedString(msgShows: IntKeyedDictionary<MsgShow>) -> AttributedString {
    var accumulator = AttributedString()

    for (index, msgShow) in msgShows.values.enumerated() {
      msgShow.contentParts
        .map { contentPart -> AttributedString in
          AttributedString(
            contentPart.text,
            attributes: .init([
              .font: font.nsFont(),
              .foregroundColor: viewStore.appearance.foregroundColor(for: contentPart.highlightID).swiftUI,
              .backgroundColor: contentPart.highlightID.isDefault ? SwiftUI.Color.clear : viewStore.appearance.backgroundColor(for: contentPart.highlightID).swiftUI,
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

struct SwiftUIView: View {
  var cellWidth: Double = 16
  var cellHeight: Double = 16
  var backgroundColor = SwiftUI.Color.black
  var foregroundColor = SwiftUI.Color.white
  var attributedString = AttributedString()

  @SwiftUI.State private var yOffset: Double = 0

  var body: some View {
    Text(attributedString)
      .offset(.init(x: 0, y: yOffset))
      .lineLimit(nil)
      .padding(
        .init(top: cellHeight, leading: cellWidth * 2.5, bottom: cellHeight, trailing: cellWidth * 2.5)
      )
      .background {
        let rectangle = Rectangle()

        rectangle
          .fill(backgroundColor.opacity(0.9))

        rectangle
          .stroke(foregroundColor.opacity(0.1), lineWidth: 1)
      }
      .transition(.opacity)
  }
}
