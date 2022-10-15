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
import SwiftUI

class Window: NSWindow, NSWindowDelegate {
  init(store: Store) {
    super.init(contentRect: .init(), styleMask: [.titled], backing: .buffered, defer: true)

    self.delegate = self
    self.contentViewController = ViewController(store: store)
  }

  override var canBecomeMain: Bool {
    true
  }

  func windowDidBecomeMain(_: Notification) {
    setContentSize(.init(width: 640, height: 480))
  }
}
