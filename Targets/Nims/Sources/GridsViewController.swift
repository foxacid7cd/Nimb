//
//  GridsViewController.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import CasePaths
import Library
import RxCocoa
import RxSwift

class GridsViewController: NSViewController {
  init() {
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    self.view = self.gridView
  }

  func handle(event: Event) {
    self.gridView.handle(event: event)
  }

  private lazy var gridView = GridsView(
    frame: CGRect(
      origin: .zero,
      size: self.cellsGeometry.cellsSize(
        for: self.store.state.outerGridSize
      )
    )
  )

  private var cellsGeometry: CellsGeometry {
    .shared
  }
}
