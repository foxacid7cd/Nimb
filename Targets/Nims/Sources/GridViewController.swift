//
//  GridViewController.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 23.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import CasePaths
import Library

class GridViewController: NSViewController {
  init(gridID: Int, cellsGeometry: CellsGeometry, glyphRunCache: Cache<Character, [GlyphRun]>) {
    self.gridID = gridID
    self.cellsGeometry = cellsGeometry
    self.glyphRunCache = glyphRunCache
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    self.view = GridView(
      frame: .init(
        origin: .zero,
        size: self.cellsGeometry.outerGridCellsSize
      ),
      gridID: self.gridID,
      cellsGeometry: self.cellsGeometry,
      glyphRunsCache: self.glyphRunCache
    )
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let gridID = self.gridID

    self <~ self.store.stateChanges
      .extract { (/StateChange.grid).extract(from: $0) }
      .filter { $0.id == gridID }
      .bind(with: self) { $0.handle(stateChange: $1.change) }
  }

  private let gridID: Int
  private let cellsGeometry: CellsGeometry
  private let glyphRunCache: Cache<Character, [GlyphRun]>

  private func handle(stateChange: StateChange.Grid.Change) {
    switch stateChange {
    case .size:
      self.view.frame.size = self.cellsGeometry.outerGridCellsSize

    default:
      break
    }
  }
}
