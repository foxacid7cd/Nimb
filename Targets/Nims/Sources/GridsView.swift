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

class GridsView: NSView, EventListener {
  init(frame: NSRect, glyphRunsCache: Cache<Character, [GlyphRun]>) {
    self.glyphRunsCache = glyphRunsCache
    super.init(frame: frame)

    self.listen()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func published(event: Event) {
    switch event {
    case let .windowFrameChanged(gridID):
      guard let window = self.state.windows[gridID] else {
        break
      }

      let cellsFrame = self.cellsGeometry.upsideDownRect(
        from: self.cellsGeometry.cellsRect(
          for: window.frame
        ),
        parentViewHeight: self.bounds.height
      )

      if let gridView = self.gridViews[gridID] {
        gridView.frame = cellsFrame
        gridView.isHidden = false

      } else {
        let gridView = GridView(
          frame: cellsFrame,
          gridID: gridID,
          glyphRunsCache: self.glyphRunsCache
        )
        self.gridViews[gridID] = gridView
        self.addSubview(gridView)
      }

    /* case let .floatingWindowFrameChanged(gridID):
      self.gridViews[gridID]?.isHidden = true

    case let .externalWindowFrameChanged(gridID):
      self.gridViews[gridID]?.isHidden = true */

    case let .windowHid(gridID):
      self.gridViews[gridID]?.isHidden = true

    case let .windowClosed(gridID):
      self.gridViews[gridID]?.removeFromSuperview()
      self.gridViews[gridID] = nil

    default:
      break
    }
  }

  private let glyphRunsCache: Cache<Character, [GlyphRun]>
  private var gridViews = [Int: GridView]()

  private var cellsGeometry: CellsGeometry {
    .shared
  }
}
