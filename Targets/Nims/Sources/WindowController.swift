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
    let window = NSWindow(
      contentRect: .init(),
      styleMask: [.titled],
      backing: .buffered,
      defer: true
    )
    window.title = "Grid \(gridID)"
    window.contentViewController = ViewController(gridID: gridID, glyphRunsCache: glyphRunsCache)
    super.init(window: window)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var charactersPressed: Observable<String> {
    charactersPressedSubject
  }

  override func keyDown(with event: NSEvent) {
    if let characters = event.characters {
      self.charactersPressedSubject.onNext(characters)

    } else {
      super.keyDown(with: event)
    }
  }

  override func keyUp(with event: NSEvent) {
    if event.characters == nil {
      super.keyUp(with: event)
    }
  }

  private let charactersPressedSubject = PublishSubject<String>()
}
