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

class GridsViewController: NSViewController, EventListener {
  init(glyphRunsCache: Cache<String, [GlyphRun]>) {
    self.glyphRunsCache = glyphRunsCache
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    self.view = GridsView(
      frame: CGRect(
        origin: .zero,
        size: self.cellsGeometry.cellsSize(
          for: self.store.state.outerGridSize
        )
      ),
      glyphRunsCache: self.glyphRunsCache
    )
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.listen()
  }

  func published(event: Event) {}

  private let glyphRunsCache: Cache<String, [GlyphRun]>

  private var cellsGeometry: CellsGeometry {
    .shared
  }
}
