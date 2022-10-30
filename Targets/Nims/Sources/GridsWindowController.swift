//
//  GridsWindowController.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 17.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Library
import RxSwift

class GridsWindowController: NSWindowController {
  init() {
    let window = GridsWindow()
    self.keyDown = window.keyDown
    super.init(window: window)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  let keyDown: Observable<NSEvent>
}
