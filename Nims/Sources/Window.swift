// Copyright © 2022 foxacid7cd. All rights reserved.

import AsyncAlgorithms
import Cocoa
import Library

@MainActor
class Window: NSWindow {
  init(style: NSWindow.StyleMask, contentView: NSView) {
    super.init(contentRect: .zero, styleMask: style, backing: .buffered, defer: true)

    self.contentView = contentView
  }

  override var canBecomeMain: Bool {
    true
  }

  override var canBecomeKey: Bool {
    true
  }

  var keyPresses: AsyncStream<KeyPress> {
    .init(self.keyPressChannel)
  }

  override func keyDown(with event: NSEvent) {
    let keyPress = KeyPress(event: event)

    Task {
      await self.keyPressChannel.send(keyPress)
    }
  }

  private let keyPressChannel = AsyncChannel<KeyPress>()
}
