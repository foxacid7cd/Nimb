//
//  GridsView.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 23.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import API
import AppKit
import CasePaths
import Combine
import Library
import RxCocoa
import RxSwift

class GridsView: NSView {
  override init(frame: CGRect) {
    super.init(frame: frame)

    for (id, window) in self.state.windows.enumerated() where window != nil {
      self.insertGridView(id: id)
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func handle(event: Event) {
    switch event {
    case let .grid(id, model):
      switch model {
      case .windowFrameChanged:
        if let gridView = self.gridViews[id] {
          gridView.frame = self.gridViewFrame(id: id)
          gridView.isHidden = self.state.windows[id]!.isHidden
          gridView.setNeedsDrawing()

        } else {
          self.insertGridView(id: id)
        }

      case .windowHid:
        self.gridViews[id]?.isHidden = true

      case .windowClosed:
        self.gridViews[id]?.removeFromSuperview()
        self.gridViews[id] = nil
        self.gridIDs.remove(id)

      case .windowGridCleared:
        self.gridViews[id]?.setNeedsDrawing()

      case let .windowGridRowChanged(origin, columnsCount):
        self.gridViews[id]?.setNeedsDrawing(
          .init(origin: origin, size: .init(rowsCount: 1, columnsCount: columnsCount))
        )

      case let .windowGridRectangleChanged(rectangle):
        self.gridViews[id]?.setNeedsDrawing(rectangle)

      case let .windowGridRectangleMoved(rectangle, toOrigin):
        let window = self.state.windows[id]!

        let toRectangle = GridRectangle(origin: toOrigin, size: rectangle.size)
          .intersection(.init(size: window.grid.size))

        if let toRectangle {
          self.gridViews[id]?.setNeedsDrawing(toRectangle)
        }
      }

    case let .cursor(previousCusor):
      if let previousCusor {
        handle(cursor: previousCusor)
      }

      if let cursor = self.state.cursor {
        handle(cursor: cursor)
      }

      func handle(cursor: State.Cursor) {
        self.gridViews[cursor.gridID]?.setNeedsDrawing(
          .init(origin: cursor.position, size: .init(rowsCount: 1, columnsCount: 1))
        )
      }

    case .appearanceChanged:
      self.gridViews.forEach { $0?.setNeedsDrawing() }

    case .flushRequested:
      for gridID in self.gridIDs {
        self.gridViews[gridID]?.flushIfNeeded()
      }
    }
  }

  private var gridViews = [GridView?](repeating: nil, count: 1000)
  private var gridIDs = Set<Int>()

  private var cellsGeometry: CellsGeometry {
    .shared
  }

  private func insertGridView(id: Int) {
    let gridView = GridView(
      frame: self.gridViewFrame(id: id),
      gridID: id
    )
    self.gridViews[id] = gridView
    self.gridIDs.insert(id)
    gridView.isHidden = self.state.windows[id]!.isHidden

    let relativeSubview = self.subviews
      .map { self.state.windows[($0 as! GridView).gridID]!.zIndex }
      .firstIndex(where: { $0 > self.state.windows[id]!.zIndex })
      .map { self.subviews[$0] }

    if let relativeSubview {
      self.addSubview(gridView, positioned: .below, relativeTo: relativeSubview)

    } else {
      self.addSubview(gridView)
    }
  }

  private func gridViewFrame(id: Int) -> CGRect {
    self.cellsGeometry.upsideDownRect(
      from: self.cellsGeometry.cellsRect(
        for: self.state.windows[id]!.frame
      ),
      parentViewHeight: self.bounds.height
    )
  }
}
