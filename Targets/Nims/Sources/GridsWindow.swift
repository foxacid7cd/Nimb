//
//  GridsWindow.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 23.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Library
import RxSwift

class GridsWindow: NSWindow {
  init(glyphRunsCache: Cache<Character, [GlyphRun]>) {
    super.init(
      contentRect: .init(),
      styleMask: [.titled],
      backing: .buffered,
      defer: true
    )
    self.contentViewController = GridsViewController(
      glyphRunsCache: glyphRunsCache
    )
  }

  var keyDown: Observable<NSEvent> {
    self.keyDownSubject
  }

  override var canBecomeKey: Bool {
    true
  }

  override func keyDown(with event: NSEvent) {
    self.keyDownSubject.onNext(event)
  }

  private let keyDownSubject = PublishSubject<NSEvent>()
}
