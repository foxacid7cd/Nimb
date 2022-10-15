//
//  Window.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Combine
import Drawing
import Library
import SwiftUI

class Window: NSWindow {
  private let store: Store
  private lazy var viewController = ViewController(store: store)

  init(store: Store) {
    self.store = store
    super.init(contentRect: .init(), styleMask: [.titled], backing: .buffered, defer: true)

    self.delegate = self
    self.contentViewController = viewController
  }

  override var canBecomeMain: Bool {
    true
  }

  private func subscribe() {
    Task {
      for await state in AsyncPublisher(store.$state) {
        guard let currentGrid = store.state.currentGrid else {
          continue
        }

        let contentSize = NSSize(
          width: CGFloat(currentGrid.width) * state.cellSize.width,
          height: CGFloat(currentGrid.height) * state.cellSize.height
        )

        setContentSize(contentSize)
      }
    }
  }

  func handle(updates: GridUpdates, forGridID id: Int) {
    viewController.handle(updates: updates, forGridID: id)
  }
}

extension Window: NSWindowDelegate {
  func windowDidBecomeMain(_ notification: Notification) {
    subscribe()
  }
}
