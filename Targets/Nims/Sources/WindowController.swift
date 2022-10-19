//
//  WindowController.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 17.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit

class WindowController: NSWindowController {
  init(gridID: Int) {
    self.gridID = gridID

    let window = NSWindow(
      contentRect: .init(),
      styleMask: [.titled],
      backing: .buffered,
      defer: true
    )
    window.contentViewController = ViewController(gridID: gridID)
    super.init(window: window)

    self.updateWindowTitle()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private let gridID: Int

  private var grid: CellGrid {
    Store.shared.state.grids[self.gridID]!
  }

  private func updateWindowTitle() {
    guard let window else { return }

    let grid = self.grid
    window.title = "Grid \(Store.shared.state.grids[self.gridID].logDescription)"
  }
}
