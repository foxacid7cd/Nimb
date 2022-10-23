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
  init(frame: NSRect, gridID: Int, glyphRunsCache: Cache<Character, [GlyphRun]>) {
    self.glyphRunsCache = glyphRunsCache
    self.mainGridView = .init(
      frame: frame,
      gridID: gridID,
      windowRef: nil,
      glyphRunsCache: glyphRunsCache
    )
    super.init(frame: frame)

    self <~ self.store.stateChanges
      .extract { (/StateChange.window).extract(from: $0) }
      .bind(with: self) { $0.handleWindow(stateChange: $1) }

    self.mainGridView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(self.mainGridView)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private let glyphRunsCache: Cache<Character, [GlyphRun]>
  private var mainGridView: GridView
  private var windowGridViews = [ExtendedTypes.Window: GridView]()

  private var cellsGeometry: CellsGeometry {
    .shared
  }

  private func handleWindow(stateChange: StateChange.Window) {
    switch stateChange.change {
    case .position:
      if let gridView = self.windowGridViews[stateChange.ref] {
        let window = self.state.grids[stateChange.gridID]!.windows[stateChange.ref]

        gridView.frame = self.cellsGeometry.cellsRect(for: window!.frame)

      } else {
        let windows = self.state.grids[stateChange.gridID]!.windows

        let gridView = GridView(
          frame: self.cellsGeometry.cellsRect(
            for: windows[stateChange.ref]!.frame
          ),
          gridID: stateChange.gridID,
          windowRef: stateChange.ref,
          glyphRunsCache: self.glyphRunsCache
        )
        gridView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(gridView)

        self.windowGridViews[stateChange.ref] = gridView
      }

    case .hide:
      self.windowGridViews[stateChange.ref]!.isHidden = true

    case .close:
      self.windowGridViews[stateChange.ref]!.removeFromSuperview()
      self.windowGridViews[stateChange.ref] = nil

    default:
      break
    }
  }
}
