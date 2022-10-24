//
//  GridWindow.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 23.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Library
import RxSwift

final class GridWindow: NSWindow {
  init(gridID: Int, glyphRunsCache: Cache<Character, [GlyphRun]>) {
    super.init(
      contentRect: .init(),
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )
    self.contentViewController = GridViewController(
      gridID: gridID,
      glyphRunCache: glyphRunsCache
    )
  }

  override var canBecomeKey: Bool {
    true
  }
}
