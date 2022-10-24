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
import RxSwift

class GridViewController: NSViewController {
  init(gridID: Int, glyphRunCache: Cache<Character, [GlyphRun]>) {
    self.gridID = gridID
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
        size: self.cellsGeometry.cellSize
      ),
      gridID: self.gridID,
      windowRef: nil,
      glyphRunsCache: self.glyphRunCache
    )
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let gridID = self.gridID

    self <~ self.store.stateChanges
      .extract { (/StateChange.grid).extract(from: $0) }
      .filter { $0.id == gridID }
      .bind(with: self) { $0.handleGrid(stateChange: $1.change) }
  }

  private let gridID: Int
  private let glyphRunCache: Cache<Character, [GlyphRun]>

  private var cellsGeometry: CellsGeometry {
    .shared
  }

  private func handleGrid(stateChange: StateChange.Grid.Change) {}
}
