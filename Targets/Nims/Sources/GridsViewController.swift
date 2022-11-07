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
  @MainActor
  init(state: State) {
    self.state = state
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    self.view = self.gridsView
  }

  @MainActor
  func handle(state: State, events: [Event]) async {
    self.state = state

    await self.gridsView.handle(state: state, events: events)
  }

  @MainActor
  private var state: State

  @MainActor
  private lazy var gridsView = GridsView(
    frame: CGRect(
      origin: .zero,
      size: CellsGeometry.cellsSize(
        for: self.state.outerGridSize,
        cellSize: self.state.fontDerivatives.cellSize
      )
    ),
    state: self.state
  )
}
