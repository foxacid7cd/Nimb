//
//  Window.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import AsyncAlgorithms
import Cocoa

@MainActor
class Window: NSWindow {
  override var canBecomeMain: Bool {
    true
  }

  override var canBecomeKey: Bool {
    true
  }

  var keyPresses: AnyAsyncSequence<KeyPress> {
    self.keyPressChannel.eraseToAnyAsyncSequence()
  }

  override func keyDown(with event: NSEvent) {
    let keyPress = KeyPress(event: event)

    Task {
      await self.keyPressChannel.send(keyPress)
    }
  }

  private let keyPressChannel = AsyncChannel<KeyPress>()
}
