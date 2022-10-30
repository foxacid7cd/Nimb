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
  init(frame: NSRect, glyphRunsCache: Cache<String, [GlyphRun]>, cgColorCache: Cache<State.Color, CGColor>) {
    self.glyphRunsCache = glyphRunsCache
    self.cgColorCache = cgColorCache
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

      let frame = self.cellsGeometry.upsideDownRect(
        from: self.cellsGeometry.cellsRect(
          for: window.frame
        ),
        parentViewHeight: self.bounds.height
      )
      if let gridView = self.gridViews[gridID] {
        gridView.frame = frame
        gridView.isHidden = window.isHidden

      } else {
        let gridView = GridView(
          frame: frame,
          gridID: gridID,
          glyphRunsCache: self.glyphRunsCache,
          cgColorCache: self.cgColorCache
        )
        self.gridViews[gridID] = gridView
        gridView.isHidden = window.isHidden

        let relativeSubview = self.subviews
          .map { self.state.windows[($0 as! GridView).gridID]!.zIndex }
          .firstIndex(where: { $0 > window.zIndex })
          .map { self.subviews[$0] }

        if let relativeSubview {
          self.addSubview(gridView, positioned: .below, relativeTo: relativeSubview)

        } else {
          self.addSubview(gridView)
        }
      }

    case let .windowHid(gridID):
      self.gridViews[gridID]?.isHidden = true

    case let .windowClosed(gridID):
      self.gridViews[gridID]?.removeFromSuperview()
      self.gridViews[gridID] = nil

    default:
      break
    }
  }

  private let glyphRunsCache: Cache<String, [GlyphRun]>
  private let cgColorCache: Cache<State.Color, CGColor>
  private var gridViews = [Int: GridView]()

  private var cellsGeometry: CellsGeometry {
    .shared
  }
}
