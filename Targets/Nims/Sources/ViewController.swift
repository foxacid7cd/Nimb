//
//  ViewController.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit

class ViewController: NSViewController {
  init(gridID: Int) {
    self.gridID = gridID
    super.init(nibName: nil, bundle: nil)
    
    self.stateChanges
      .compactMap { $0.grid(id: gridID)?.size }
      .bindFlat { [weak self] (store, size) in
        self?.view.frame.size =
          .init(width: size.columnsCount, height: size.rowsCount)
      }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    self.view = GridView(
      frame: .zero,
      gridID: self.gridID
    )
  }

  private let gridID: Int
}
