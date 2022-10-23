//
//  ViewController.swift
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

class ViewController: NSViewController {
  init(gridID: Int, glyphRunsCache: Cache<Character, [GlyphRun]>) {
    self.gridID = gridID
    self.cellsGeometry = CellsGeometry(gridID: gridID)
    self.glyphRunsCache = glyphRunsCache
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    self.view = GridView(
      frame: self.gridCellsFrame,
      gridID: self.gridID,
      cellsGeometry: self.cellsGeometry,
      glyphRunsCache: .init()
    )
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let gridID = self.gridID

    self <~ self.store.stateChanges
      .extract { (/StateChange.grid).extract(from: $0) }
      .filter { $0.id == gridID }
      .compactMap { (/StateChange.Grid.Change.size).extract(from: $0.change) }
      .bind(with: self) { strongSelf, _ in
        strongSelf.view.frame = strongSelf.gridCellsFrame
      }
  }

  private let gridID: Int
  private let cellsGeometry: CellsGeometry
  private let glyphRunsCache: Cache<Character, [GlyphRun]>

  private var grid: CellGrid {
    self.store.state.grids[self.gridID]!
  }

  private var gridCellsSize: CGSize {
    self.cellsGeometry.cellsSize(for: self.grid.size)
  }

  private var gridCellsFrame: CGRect {
    .init(
      origin: .zero,
      size: self.gridCellsSize
    )
  }
}
