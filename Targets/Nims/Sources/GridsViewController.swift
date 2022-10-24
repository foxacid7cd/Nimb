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
  init(gridID: Int, glyphRunsCache: Cache<Character, [GlyphRun]>) {
    self.gridID = gridID
    self.glyphRunsCache = glyphRunsCache
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    self.view = GridsView(
      frame: .init(
        origin: .init(),
        size: self.grid.flatMap {
          self.cellsGeometry.cellsSize(for: $0.cellGrid.size)
        } ?? .init()
      ),
      gridID: self.gridID,
      glyphRunsCache: self.glyphRunsCache
    )
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self <~ self.store.stateChanges
      .extract { (/StateChange.grid).extract(from: $0)?.change }
      .bind(with: self) { $0.handle(stateChange: $1) }
  }

  private let gridID: Int
  private let glyphRunsCache: Cache<Character, [GlyphRun]>

  private var cellsGeometry: CellsGeometry {
    .shared
  }

  private var grid: State.Grid? {
    self.state.grids[self.gridID]
  }

  private func handle(stateChange: StateChange.Grid.Change) {
    switch stateChange {
    case .size:
      self.view.frame = .init(
        origin: .init(),
        size: self.grid.flatMap {
          self.cellsGeometry.cellsSize(for: $0.cellGrid.size)
        } ?? .init()
      )

    default:
      break
    }
  }
}
