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

  init(store: Store) {
    self.store = store
    super.init(contentRect: .init(), styleMask: [.titled], backing: .buffered, defer: true)

    self.delegate = self
    self.contentViewController = ViewController(store: store)
  }

  override var canBecomeMain: Bool {
    true
  }
}

extension Window: NSWindowDelegate {
  func windowDidBecomeMain(_ notification: Notification) {
    Task {
      for await state in AsyncPublisher(store.$state) {
        guard let currentGridID = state.currentGridID, let currentGrid = state.grids[currentGridID] else {
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
}
