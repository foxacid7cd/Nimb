// SPDX-License-Identifier: MIT

// import AsyncAlgorithms
// import Cocoa
// import Library
//
// @MainActor class Window: NSWindow {
//  override var canBecomeMain: Bool { true }
//
//  override var canBecomeKey: Bool { true }
//
//  var keyPresses: AsyncStream<KeyPress> {
//    self.keyPressChannel.erasedToAsyncStream
//  }
//
//  override func keyDown(with event: NSEvent) {
//    let keyPress = KeyPress(event: event)
//
//    Task {
//      await self.keyPressChannel.send(keyPress)
//    }
//  }
//
//  private let keyPressChannel = AsyncChannel<KeyPress>()
// }
