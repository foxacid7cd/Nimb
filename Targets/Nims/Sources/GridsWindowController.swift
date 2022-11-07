//
//  GridsWindowController.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 17.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import API
import AppKit
import Library
import RxSwift

class GridsWindowController: NSWindowController {
  init() {
    let gridsWindow = GridsWindow()
    self.gridsWindow = gridsWindow
    super.init(window: gridsWindow)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var input: Observable<Input> {
    self.gridsWindow.input
  }

  func handle(event: Event) {
    self.gridsWindow.handle(event: event)
  }

  private let gridsWindow: GridsWindow
}
