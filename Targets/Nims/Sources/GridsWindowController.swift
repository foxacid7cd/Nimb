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
  @MainActor
  init(state: State) {
    let gridsWindow = GridsWindow(state: state)
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

  @MainActor
  func handle(state: State, events: [Event]) async {
    await self.gridsWindow.handle(state: state, events: events)
  }

  private let gridsWindow: GridsWindow
}
