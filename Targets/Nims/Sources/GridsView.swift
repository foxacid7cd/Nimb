//
//  GridsView.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 23.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import CasePaths
import Combine
import Library
import Nvim
import RxCocoa
import RxSwift

class GridsView: NSView {
  init(frame: NSRect, glyphRunsCache: Cache<Character, [GlyphRun]>) {
    self.glyphRunsCache = glyphRunsCache
    super.init(frame: frame)

    self <~ self.store.stateChanges
      .extract { (/StateChange.grid).extract(from: $0) }
      .bind(with: self) { $0.handle(stateChange: $1) }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private let glyphRunsCache: Cache<Character, [GlyphRun]>
  private var gridViews = [(cellsGeometry: CellsGeometry, gridView: GridView)?](repeating: nil, count: 100)

  private func handle(stateChange: StateChange.Grid) {
    switch stateChange.change {
    case .windowPosition:
      let window = self.state.grids[stateChange.id]!.window!
      if let (cellsGeometry, gridView) = self.gridViews[stateChange.id] {
        gridView.frame = cellsGeometry.cellsRect(for: window.frame)
        gridView.isHidden = false

      } else {
        let cellsGeometry = CellsGeometry()
        let gridView = GridView(
          frame: cellsGeometry.cellsRect(for: window.frame),
          gridID: stateChange.id,
          cellsGeometry: cellsGeometry,
          glyphRunsCache: self.glyphRunsCache
        )
        self.gridViews[stateChange.id] = (cellsGeometry, gridView)
        gridView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(gridView)
      }

    case .windowHide:
      if let (_, gridView) = self.gridViews[stateChange.id] {
        gridView.isHidden = true

      } else {
        "Trying to hide unexisting window"
          .fail()
          .assertionFailure()
      }

    case .windowClose:
      self.gridViews[stateChange.id]?.gridView.removeFromSuperview()
      self.gridViews[stateChange.id] = nil

    default:
      break
    }
  }
}
