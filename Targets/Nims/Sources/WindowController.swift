//
//  WindowController.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 17.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Library
import RxSwift

class WindowController: NSWindowController {
  init(gridID: Int, glyphRunsCache: Cache<Character, [GlyphRun]>) {
    let window = Window(gridID: gridID, glyphRunsCache: glyphRunsCache)
    self.keyDown = window.keyDown
    super.init(window: window)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  let keyDown: Observable<NSEvent>
}

private class Window: NSWindow {
  init(gridID: Int, glyphRunsCache: Cache<Character, [GlyphRun]>) {
    super.init(
      contentRect: .init(),
      styleMask: [.titled],
      backing: .buffered,
      defer: true
    )
    self.title = "Grid \(gridID)"
    self.contentViewController = ViewController(
      gridID: gridID,
      glyphRunsCache: glyphRunsCache
    )
  }

  var keyDown: Observable<NSEvent> {
    self.keyDownSubject
  }

  override func keyDown(with event: NSEvent) {
    self.keyDownSubject.onNext(event)
  }

  private let keyDownSubject = PublishSubject<NSEvent>()
}
