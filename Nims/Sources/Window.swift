//
//  Window.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import AsyncAlgorithms
import Backbone
import Cocoa

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
    self.keyPressChannel.asyncStream()
  }

  override func keyDown(with event: NSEvent) {
    let keyPress = KeyPress(event: event)

    Task {
      await self.keyPressChannel.send(keyPress)
    }
  }

  private let keyPressChannel = AsyncChannel<KeyPress>()
}
