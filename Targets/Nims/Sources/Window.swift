//
//  Window.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Combine
import Library

class Window: NSWindow, NSWindowDelegate {
  init(store: Store) {
    self.store = store
    super.init(
      contentRect: .init(),
      styleMask: [.titled],
      backing: .buffered,
      defer: true
    )

    self.delegate = self
    self.contentViewController = ViewController(store: store)
    self.subtitle = "nvim"

    self.updateSubtitle()

    store.notifications
      .sink { [weak self] in self?.handle(notifications: $0) }
      .store(in: &self.cancellables)
  }

  override var canBecomeMain: Bool {
    true
  }

  private let store: Store
  private var cancellables = Set<AnyCancellable>()

  private func handle(notifications: [Store.Notification]) {
    for notification in notifications {
      switch notification {
      case .currentGridChanged:
        self.updateSubtitle()

      default:
        continue
      }
    }
  }

  private func updateSubtitle() {
    self.subtitle = self.store.state.currentGridID.map { "Grid \($0)" } ?? ""
  }
}
